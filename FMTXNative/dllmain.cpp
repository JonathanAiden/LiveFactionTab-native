#define NOMINMAX
#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <cstring>
#include <mutex>
#include <string>
#include <vector>
#include <algorithm>
#include <format>
#include <Mod/CppUserModBase.hpp>
#include <DynamicOutput/DynamicOutput.hpp>
#include <LuaMadeSimple/LuaMadeSimple.hpp>
#include <Unreal/UObjectGlobals.hpp>
#include <Unreal/UObject.hpp>
#include <Unreal/UFunction.hpp>
#include <Unreal/UClass.hpp>
#include <Unreal/NameTypes.hpp>
#include <Unreal/Hooks/Hooks.hpp>

using namespace RC;
using namespace RC::Unreal;

namespace
{
    struct FOptId { uint64_t Id; bool Ok; uint8_t Pad[7]; };
    using LookupFn = FOptId* (__fastcall*)(FOptId*, const uint64_t*);
    using RelationFn = uint8_t* (__fastcall*)(void*, uint64_t, uint64_t, uint32_t);

    constexpr uintptr_t RVA_LOOKUP = 0x2C695C, RVA_RELATION = 0x25902BC, RVA_WORLD = 0xAE05AD8;
    const uint8_t SIG_LOOKUP[] = {0x56, 0x48, 0x83, 0xEC, 0x30, 0x48, 0x89, 0xCE, 0x48, 0x8B, 0x05};
    const uint8_t SIG_RELATION[] = {0x41, 0x57, 0x41, 0x56, 0x41, 0x55, 0x41, 0x54, 0x56, 0x57, 0x55, 0x53, 0x48, 0x81, 0xEC, 0xD8};

    const char* FACTIONS[] = {"Player", "Duty", "Freedom", "Varta", "Neutrals", "Scientists", "Spark",
                              "Corpus", "Noon", "Militaries", "Mercenaries", "Bandits", "Monolith"};

    std::mutex CacheLock;
    std::string Cache;

    int LuaMatrix(const LuaMadeSimple::Lua& Lua)
    {
        std::lock_guard Guard(CacheLock);
        if (Cache.empty()) Lua.set_nil();
        else Lua.set_string(Cache);
        return 1;
    }
}

class FactionMatrixNative : public CppUserModBase
{
    uintptr_t Base{};
    LookupFn Lookup{};
    RelationFn Relation{};
    bool Valid{};
    bool Announced{};
    uint64_t Next{};
    UFunction* FnButtonClicked{};
    std::vector<UFunction*> FnViewEvents;
    UObject* TabButton{};
    uint8_t LineVisible{4};
    bool LineKnown{};
    UFunction* FnConstruct{};
    UClass* ViewClass{};
    bool Building{};

public:
    FactionMatrixNative() : CppUserModBase()
    {
        ModName = STR("FactionMatrixNative");
        ModVersion = STR("1.0");
        ModDescription = STR("Reads faction relations directly for Faction Relations - Live PDA Tab");
        ModAuthors = STR("Godmc");
        Base = reinterpret_cast<uintptr_t>(GetModuleHandleW(nullptr));
        Valid = std::memcmp(reinterpret_cast<void*>(Base + RVA_LOOKUP), SIG_LOOKUP, sizeof(SIG_LOOKUP)) == 0 &&
                std::memcmp(reinterpret_cast<void*>(Base + RVA_RELATION), SIG_RELATION, sizeof(SIG_RELATION)) == 0;
        Lookup = reinterpret_cast<LookupFn>(Base + RVA_LOOKUP);
        Relation = reinterpret_cast<RelationFn>(Base + RVA_RELATION);
        Output::send<LogLevel::Verbose>(Valid ? STR("[FMTX native] 1.0 loaded, game version matches\n")
                                              : STR("[FMTX native] 1.0 loaded, GAME VERSION NOT SUPPORTED - native reading off, the tab uses quest measurement\n"));
    }
    ~FactionMatrixNative() override {}

    auto on_unreal_init() -> void override
    {
        FnButtonClicked = UObjectGlobals::StaticFindObject<UFunction*>(nullptr, nullptr, STR("/Script/Stalker2.ButtonBase:ButtonClicked"));
        for (auto Path : {STR("/Script/Stalker2.BookViewBase:ChangeSelectButton"), STR("/Script/Stalker2.BookViewBase:ClickMenuButton"),
                          STR("/Script/Stalker2.PDAView:UpdateQuestList"), STR("/Script/Stalker2.PDAView:HideAllWindows")})
            if (auto F = UObjectGlobals::StaticFindObject<UFunction*>(nullptr, nullptr, Path)) FnViewEvents.push_back(F);
        FnConstruct = UObjectGlobals::StaticFindObject<UFunction*>(nullptr, nullptr, STR("/Script/UMG.UserWidget:Construct"));
        Hook::RegisterProcessEventPostCallback([this](UObject* Context, UFunction* Function, void*) { OnProcessEvent(Context, Function); });
    }

    auto on_lua_start(StringViewType ModName, LuaMadeSimple::Lua& Lua, LuaMadeSimple::Lua& MainLua, LuaMadeSimple::Lua& AsyncLua, LuaMadeSimple::Lua* HookLua) -> void override
    {
        if (ModName != STR("FactionMatrix")) return;
        Lua.register_function("FMTXNative", &LuaMatrix);
        MainLua.register_function("FMTXNative", &LuaMatrix);
        AsyncLua.register_function("FMTXNative", &LuaMatrix);
        if (HookLua) HookLua->register_function("FMTXNative", &LuaMatrix);
        Output::send<LogLevel::Verbose>(STR("[FMTX native] connected to FactionMatrix\n"));
    }

    static auto Prop(UObject* O, const TCHAR* Name) -> UObject*
    {
        if (!O) return nullptr;
        auto P = O->GetValuePtrByPropertyNameInChain<UObject*>(Name);
        return P ? *P : nullptr;
    }
    static auto Call(UObject* O, const TCHAR* Name, void* Params) -> bool
    {
        if (!O) return false;
        UFunction* F = O->GetFunctionByNameInChain(Name);
        if (!F) return false;
        O->ProcessEvent(F, Params);
        return true;
    }
    static auto Children(UObject* Panel) -> std::vector<UObject*>
    {
        std::vector<UObject*> Out;
        auto Slots = Panel->GetValuePtrByPropertyNameInChain<TArray<UObject*>>(STR("Slots"));
        if (Slots)
            for (UObject* S : *Slots)
                if (S) Out.push_back(Prop(S, STR("Content")));
        return Out;
    }
    static auto Find(const std::vector<UObject*>& List, const TCHAR* Name) -> UObject*
    {
        for (UObject* K : List)
            if (K && K->GetName() == Name) return K;
        return nullptr;
    }
    static auto CopyBool(UObject* To, UObject* From, const TCHAR* Name) -> void
    {
        auto A = To->GetValuePtrByPropertyNameInChain<bool>(Name);
        auto B = From->GetValuePtrByPropertyNameInChain<bool>(Name);
        if (A && B) *A = *B;
    }
    auto Attach(UObject* Panel, UObject* Widget) -> bool
    {
        struct { UObject* Content; UObject* ReturnValue; } P{Widget, nullptr};
        return Call(Panel, STR("AddChild"), &P) && P.ReturnValue;
    }
    auto EnsureTab(UObject* View) -> void
    {
        UObject* Nav = Prop(View, STR("NavigationPanel"));
        UObject* Container = Prop(Nav, STR("SlotContainer"));
        UObject* Switcher = Prop(View, STR("Switcher"));
        UObject* NavTree = Prop(Nav, STR("WidgetTree"));
        UObject* ViewTree = Prop(View, STR("WidgetTree"));
        UObject* PageTemplate = Prop(View, STR("StatisticPage"));
        if (!Container || !Switcher || !NavTree || !ViewTree || !PageTemplate) return;
        auto Buttons = Children(Container);
        auto Pages = Children(Switcher);
        UObject* Button = Find(Buttons, STR("FMTX_Reiter"));
        UObject* Page = Find(Pages, STR("FMTX_Seite"));
        if (Button && Page) { TabButton = Button; return; }
        if (Buttons.empty() || !Buttons[0]) return;
        struct { UObject* ReturnValue; } Owner{};
        Call(View, STR("GetOwningPlayer"), &Owner);
        if (!Button)
        {
            FStaticConstructObjectParameters P(Buttons[0]->GetClassPrivate(), NavTree);
            P.Name = FName(STR("FMTX_Reiter"), FNAME_Add);
            Button = UObjectGlobals::StaticConstructObject(P);
            if (!Button) return;
            if (auto Id = Button->GetValuePtrByPropertyNameInChain<FName>(STR("ButtonId"))) *Id = FName(STR("FMTX_Factions"), FNAME_Add);
            if (auto Loc = Button->GetValuePtrByPropertyNameInChain<bool>(STR("bEnableLocalisation"))) *Loc = false;
            if (Owner.ReturnValue) { struct { UObject* PC; } O{Owner.ReturnValue}; Call(Button, STR("SetOwningPlayer"), &O); }
            if (!Attach(Container, Button)) { Output::send<LogLevel::Warning>(STR("[FMTX native] tab button could not be attached\n")); return; }
        }
        if (!Page)
        {
            FStaticConstructObjectParameters P(PageTemplate->GetClassPrivate(), ViewTree);
            P.Name = FName(STR("FMTX_Seite"), FNAME_Add);
            Page = UObjectGlobals::StaticConstructObject(P);
            if (!Page) return;
            CopyBool(Page, PageTemplate, STR("bShouldBindWidgetInputs"));
            CopyBool(Page, PageTemplate, STR("bShoudIgnoreInputOnPouse"));
            if (Owner.ReturnValue) { struct { UObject* PC; } O{Owner.ReturnValue}; Call(Page, STR("SetOwningPlayer"), &O); }
            if (!Attach(Switcher, Page)) { Output::send<LogLevel::Warning>(STR("[FMTX native] tab page could not be attached\n")); return; }
        }
        TabButton = Button;
        Output::send<LogLevel::Verbose>(STR("[FMTX native] own PDA tab added ({} tabs, {} pages)\n"), Children(Container).size(), Children(Switcher).size());
    }
    auto FixUnderline(UObject* View) -> void
    {
        if (!TabButton) return;
        UObject* Switcher = Prop(View, STR("Switcher"));
        UObject* Line = Prop(TabButton, STR("SelectLine"));
        if (!Switcher || !Line) return;
        if (!LineKnown)
        {
            if (auto V = Line->GetValuePtrByPropertyNameInChain<uint8_t>(STR("Visibility"))) LineVisible = *V == 1 || *V == 2 ? 4 : *V;
            LineKnown = true;
        }
        struct { int32_t ReturnValue; } Active{-1};
        Call(Switcher, STR("GetActiveWidgetIndex"), &Active);
        auto Pages = Children(Switcher);
        int32_t Own = -1;
        for (int32_t i = 0; i < static_cast<int32_t>(Pages.size()); ++i)
            if (Pages[i] && Pages[i]->GetName() == STR("FMTX_Seite")) Own = i;
        struct { uint8_t Vis; } P{static_cast<uint8_t>(Active.ReturnValue == Own ? LineVisible : 2)};
        Call(Line, STR("SetVisibility"), &P);
    }
    auto OnProcessEvent(UObject* Context, UFunction* Function) -> void
    {
        if (Building || !Context) return;
        Building = true;
        if (Function == FnButtonClicked && Context == TabButton)
        {
            UObject* Nav = Context->GetOuterPrivate() ? Context->GetOuterPrivate()->GetOuterPrivate() : nullptr;
            struct { FName Id; } P{FName(STR("FMTX_Factions"), FNAME_Add)};
            Call(Nav, STR("ClickMenuButton"), &P);
        }
        else if (Function == FnConstruct)
        {
            UClass* Class = Context->GetClassPrivate();
            if (!ViewClass && Class && Class->GetName() == STR("W_PDABookView_C")) ViewClass = Class;
            if (Class && Class == ViewClass) EnsureTab(Context);
        }
        else if (std::find(FnViewEvents.begin(), FnViewEvents.end(), Function) != FnViewEvents.end())
        {
            ViewClass = Context->GetClassPrivate();
            EnsureTab(Context);
            FixUnderline(Context);
        }
        Building = false;
        if (Valid) Tick();
    }
#ifdef FMTX_DIAG
    UObject* LetzteView{};
    auto Diag() -> void
    {
        UObject* View = UObjectGlobals::FindFirstOf(STR("W_PDABookView_C"));
        if (!View || View == LetzteView) return;
        LetzteView = View;
        auto Q = [](void* P, int O) { return *reinterpret_cast<uintptr_t*>(reinterpret_cast<uint8_t*>(P) + O); };
        auto R = [this](uintptr_t V) { return (V > Base && V < Base + 0x10000000) ? V - Base : V; };
        std::wstring T = L"[FMTX diag] BookView " + View->GetFullName() + L"\n  vtable rva " + std::format(L"{:X}", R(Q(View, 0)));
        uintptr_t Vt = Q(View, 0);
        for (int O = 0x500; O <= 0x560; O += 8) T += std::format(L"\n  vt+{:X} = {:X}", O, R(*reinterpret_cast<uintptr_t*>(Vt + O)));
        for (int O = 0x320; O < 0x3F0; O += 8) T += std::format(L"\n  view+{:X} = {:X}", O, R(Q(View, O)));
        void* Nav = reinterpret_cast<void*>(Q(View, 0x330));
        if (Nav)
        {
            T += std::format(L"\n  nav vtable rva {:X}", R(Q(Nav, 0)));
            for (int O = 0x2D0; O < 0x3E0; O += 8) T += std::format(L"\n  nav+{:X} = {:X}", O, R(Q(Nav, O)));
        }
        Output::send<LogLevel::Verbose>(STR("{}\n"), T);
    }
#endif
    auto Tick() -> void
    {
        const uint64_t Now = GetTickCount64();
        if (Now < Next) return;
        Next = Now + 2000;
#ifdef FMTX_DIAG
        Diag();
#endif
        std::vector<std::pair<const char*, uint64_t>> Ids;
        for (auto Name : FACTIONS)
        {
            std::wstring WName(Name, Name + std::strlen(Name));
            FName N(WName.c_str(), FNAME_Find);
            if (N.GetComparisonIndex().ToUnstableInt() == 0) continue;
            uint64_t Raw = static_cast<uint64_t>(N.GetComparisonIndex().ToUnstableInt()) | (static_cast<uint64_t>(N.GetNumber()) << 32);
            FOptId Out{};
            Lookup(&Out, &Raw);
            if (Out.Ok) Ids.emplace_back(Name, Out.Id);
        }
        std::string Text;
        if (Ids.size() == std::size(FACTIONS))
        {
            for (auto& [NameA, A] : Ids)
                for (auto& [NameB, B] : Ids)
                {
                    if (A == B) continue;
                    uint8_t* Entry = Relation(reinterpret_cast<void*>(Base + RVA_WORLD), A, B, 0);
                    if (!Entry) continue;
                    Text += NameA; Text += ' '; Text += NameB; Text += ' ';
                    Text += std::to_string(*reinterpret_cast<int32_t*>(Entry + 0x10)); Text += '\n';
                }
        }
        {
            std::lock_guard Guard(CacheLock);
            Cache = std::move(Text);
        }
        if (!Announced && !Cache.empty())
        {
            Announced = true;
            Output::send<LogLevel::Verbose>(STR("[FMTX native] relations readable ({} factions)\n"), Ids.size());
        }
    }
};

extern "C"
{
    __declspec(dllexport) RC::CppUserModBase* start_mod() { return new FactionMatrixNative(); }
    __declspec(dllexport) void uninstall_mod(RC::CppUserModBase* mod) { delete mod; }
}
