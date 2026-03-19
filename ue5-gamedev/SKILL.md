---
name: ue5-gamedev
description: >
  Unreal Engine 5 game development: C++ coding, Blueprint creation, editor automation,
  and build management. Use when tasks involve writing UE5 C++ gameplay code, creating
  or modifying Blueprints, executing editor commands, triggering builds, or working with
  the UE5 project via Remote Control API, Python bridge, or MCP tools. Covers coding
  standards, UPROPERTY/UFUNCTION macros, gameplay framework classes, and remote editor
  interaction.
---

# UE5 Game Development

C++ coding, Blueprint authoring, editor automation, and build management for Unreal Engine 5 projects.

## Infrastructure

UE5 requires a machine with a capable GPU and sufficient RAM. Remote access to the editor is provided through multiple channels. Configure the following environment variables (or use the defaults shown):

| Service | Env Var | Default | Purpose |
|---------|---------|---------|---------|
| Remote Control API | `UE5_REMOTE_CONTROL_HOST` | `localhost:8080` | Property access, function calls, editor control |
| UE5 Editor (Remote Exec) | `UE5_PYTHON_BRIDGE_HOST` | `localhost:30010` | Python script execution inside editor |
| Bridge / Orchestrator (optional) | `UE5_BRIDGE_HOST` | `localhost:8000` | Proxied UE5 commands from an orchestrator service |

**Project path**: Set `UE5_PROJECT_PATH` to your `.uproject` directory (e.g., `D:\UnrealProjects\MyGame`).

## C++ coding standards

Follow Epic's conventions strictly:

### Naming prefixes
- `F` -- Structs (FVector, FHitResult, FMyStruct)
- `U` -- UObject-derived classes (UActorComponent, UMyComponent)
- `A` -- Actor-derived classes (ACharacter, AMyActor)
- `E` -- Enums (ECollisionChannel, EMyEnum)
- `I` -- Interfaces (IInteractable)
- `T` -- Templates (TArray, TMap, TSubclassOf)
- `b` -- Boolean variables (bIsAlive, bCanJump)

### UPROPERTY specifiers

```cpp
// Editable in editor, visible in Blueprints
UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Combat")
float MaxHealth = 100.f;

// Set in Blueprint, read-only in editor
UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Status")
bool bIsAlive = true;

// Replicated property
UPROPERTY(ReplicatedUsing = OnRep_Health)
float Health;

// Not exposed, internal only
UPROPERTY()
float InternalTimer;
```

### UFUNCTION specifiers

```cpp
// Callable from Blueprints
UFUNCTION(BlueprintCallable, Category = "Combat")
void TakeDamage(float Amount);

// Implementable in Blueprints (no C++ body)
UFUNCTION(BlueprintImplementableEvent, Category = "Events")
void OnDeath();

// C++ default with Blueprint override option
UFUNCTION(BlueprintNativeEvent, Category = "Events")
void OnHit(const FHitResult& Hit);

// Server RPC
UFUNCTION(Server, Reliable, WithValidation)
void ServerFireWeapon();
```

### Container types
- `TArray<T>` -- Dynamic array (not std::vector)
- `TMap<K, V>` -- Hash map (not std::map)
- `TSet<T>` -- Hash set
- `TSubclassOf<T>` -- Type-safe class reference
- `TSoftObjectPtr<T>` -- Lazy-loaded asset reference
- `TWeakObjectPtr<T>` -- Non-owning reference

### Rules
- No raw `new`/`delete` -- use `NewObject<T>()`, `CreateDefaultSubobject<T>()`, or smart pointers
- Use `FString`, `FName`, `FText` -- never `std::string`
- Keep functions under 50 lines
- Use `const` correctness everywhere
- Document all public interfaces with `/** */` comments
- Use `#pragma once` (not include guards)
- Include "CoreMinimal.h" first, then project headers

### Gameplay framework classes

| Class | Purpose | When to use |
|-------|---------|-------------|
| `AGameModeBase` | Game rules, spawning | Match/session logic |
| `AGameStateBase` | Shared game state | Score, match status |
| `APlayerController` | Player input routing | Camera, input, HUD |
| `APlayerState` | Per-player state | Player score, team |
| `APawn` / `ACharacter` | Controllable entities | Players, NPCs |
| `UActorComponent` | Logic components | Reusable behaviors |
| `USceneComponent` | Spatial components | Transform hierarchy |
| `UGameInstanceSubsystem` | Persistent systems | Save data, settings |
| `UWorldSubsystem` | Per-world systems | Level-scoped logic |

## Remote Control API

The Remote Control API plugin exposes UE5 editor functionality over HTTP.

### Read a property

```
PUT http://localhost:8080/remote/object/property
{
  "objectPath": "/Game/Maps/MainLevel.MainLevel:PersistentLevel.BP_Player_C_0",
  "propertyName": "MaxHealth"
}
```

### Set a property

```
PUT http://localhost:8080/remote/object/property
{
  "objectPath": "/Game/Maps/MainLevel.MainLevel:PersistentLevel.BP_Player_C_0",
  "propertyName": "MaxHealth",
  "propertyValue": { "MaxHealth": 200.0 }
}
```

### Call a function

```
PUT http://localhost:8080/remote/object/call
{
  "objectPath": "/Game/Maps/MainLevel.MainLevel:PersistentLevel.BP_Player_C_0",
  "functionName": "TakeDamage",
  "parameters": { "Amount": 50.0 }
}
```

### Search for objects

```
PUT http://localhost:8080/remote/search/object
{
  "query": "BP_Player",
  "class": "/Script/Engine.Actor",
  "outerPath": "/Game/Maps/MainLevel"
}
```

### Execute console command

```
PUT http://localhost:8080/remote/object/call
{
  "objectPath": "/Script/Engine.Default__KismetSystemLibrary",
  "functionName": "ExecuteConsoleCommand",
  "parameters": {
    "WorldContextObject": "/Game/Maps/MainLevel.MainLevel",
    "Command": "stat fps"
  }
}
```

## Python bridge

UE5's Python Editor Script Plugin exposes the `unreal` module inside the editor. Execute Python remotely via port 30010.

### Common operations

```python
import unreal

# Get the editor subsystem
editor = unreal.EditorLevelLibrary()

# Spawn an actor
location = unreal.Vector(0, 0, 100)
rotation = unreal.Rotator(0, 0, 0)
actor = editor.spawn_actor_from_class(unreal.StaticMeshActor, location, rotation)

# Set a mesh
mesh_component = actor.get_component_by_class(unreal.StaticMeshComponent)
mesh = unreal.EditorAssetLibrary.load_asset("/Engine/BasicShapes/Cube")
mesh_component.set_static_mesh(mesh)

# Find actors
actors = unreal.EditorLevelLibrary.get_all_level_actors()
player_starts = unreal.GameplayStatics.get_all_actors_of_class(
    unreal.EditorLevelLibrary.get_editor_world(),
    unreal.PlayerStart
)

# Asset operations
unreal.EditorAssetLibrary.rename_asset("/Game/Old/Path", "/Game/New/Path")
unreal.EditorAssetLibrary.duplicate_asset("/Game/Source", "/Game/Copy")
unreal.EditorAssetLibrary.delete_asset("/Game/Unused/Asset")

# Blueprint operations
factory = unreal.BlueprintFactory()
factory.set_editor_property("parent_class", unreal.Actor)
asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
blueprint = asset_tools.create_asset("BP_MyActor", "/Game/Blueprints", None, factory)
```

### Remote execution from external script

```python
# Uses UE5's remote_execution.py (bundled with Python Editor Script Plugin)
# Or use the upyrc package: pip install upyrc
import remote_execution

remote = remote_execution.RemoteExecution()
remote.start()
# Wait for node discovery
nodes = remote.remote_nodes
# Execute on first found editor
remote.run_command("print('Hello from external!')", exec_node=nodes[0])
remote.stop()
```

## UE5 Bridge API (optional orchestrator / proxy)

If you run a bridge or orchestrator service that proxies commands to the UE5 editor host, configure it with `UE5_BRIDGE_HOST`. This is useful when the machine running Claude Code is not the same machine running UE5, or when you want centralized command routing.

Example endpoints (adjust host/port to your setup):

```
# Check UE5 connectivity
GET http://localhost:8000/ue5/status

# Trigger a build
POST http://localhost:8000/ue5/build
{
  "project_path": "D:\\UnrealProjects\\MyGame",
  "config": "Development",
  "platform": "Win64",
  "cook_content": true
}

# Check build status
GET http://localhost:8000/ue5/build/{job_id}

# Execute editor command
POST http://localhost:8000/ue5/editor/command
{ "command": "open_level", "args": {"level": "/Game/Maps/MainLevel"} }

# List assets
GET http://localhost:8000/ue5/assets?path=/Game&asset_type=Blueprint

# Import asset
POST http://localhost:8000/ue5/import
{
  "source_path": "\\\\server\\exports\\character.fbx",
  "destination_path": "/Game/Characters/Imported"
}
```

## Open-source MCP servers

These MCP servers provide additional UE5 integration capabilities:

### ChiR24/Unreal_mcp (recommended)

Native C++ automation bridge.

- **Install**: `npm install -g unreal-engine-mcp-server`
- **Capabilities**: Actor creation/manipulation, asset management, Blueprint operations, lighting control, animation sequencing, audio management, console commands
- **Architecture**: TypeScript server + C++ UE integration
- **Repo**: https://github.com/ChiR24/Unreal_mcp

### chongdashu/unreal-mcp

Remote Control API based. Includes a pre-configured UE5.5 starter project.

- **Capabilities**: Create/delete actors, set transforms, query properties, create Blueprint classes, add components, configure input mappings
- **Repo**: https://github.com/chongdashu/unreal-mcp

### appleweed/UnrealMCPBridge

Direct Python API access via MCP. Available on Fab Store.

- **Capabilities**: Full `unreal` Python module access through MCP
- **Setup**: Install plugin, click "Start MCP Bridge" toolbar button (socket on 127.0.0.1:9000)
- **Repo**: https://github.com/appleweed/UnrealMCPBridge

### ayeletstudioindia/unreal-analyzer-mcp

Source code analysis and understanding (read-only).

- **Capabilities**: Class analysis, inheritance mapping, code search, reference finding, pattern detection
- **Tech**: TypeScript + Tree-sitter C++ parsing
- **Repo**: https://github.com/ayeletstudioindia/unreal-analyzer-mcp

## Blueprint best practices

When creating or modifying Blueprints:

- **Keep logic in C++, expose to Blueprints**: Use `BlueprintCallable` for functions, `BlueprintReadWrite`/`BlueprintReadOnly` for properties
- **Use BlueprintNativeEvent** for functions that designers should be able to override
- **Use BlueprintImplementableEvent** for pure designer hooks (no C++ implementation)
- **Prefer components over inheritance**: Attach behavior via UActorComponent subclasses
- **Use Data Assets** for configuration data (not hardcoded values in Blueprints)
- **Use Gameplay Tags** instead of enums for extensible categorization
- **Use Gameplay Abilities** (GAS) for complex ability systems
- **Blueprint interfaces** for cross-Blueprint communication (not casting)

## Build workflow

1. **Check UE5 status**: `GET /ue5/status` -- ensure editor is running
2. **Save all**: Execute editor command to save before building
3. **Trigger build**: `POST /ue5/build` with desired config
4. **Monitor**: Poll `GET /ue5/build/{job_id}` for status
5. **Configs**: Development (debug), DebugGame (optimized+debug), Shipping (release)

## Troubleshooting

- **Can't connect to UE5 host**: Check network connectivity, verify UE5 is running, test `curl http://localhost:8080/status`
- **Remote Control not responding**: Ensure Remote Control API + Web Remote Control plugins are enabled in the project
- **Python bridge timeout**: Editor may be busy (compiling shaders, loading level). Retry after delay.
- **Build failures**: Check build logs on the UE5 host. Common issues: missing includes, GENERATED_BODY() macro, circular dependencies.
