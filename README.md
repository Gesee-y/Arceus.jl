# Arceus.jl

**Arceus.jl** is a high-performance entity resolution engine based on [magic bitboards](https://www.chessprogramming.org/Magic_Bitboards), originally forked from [AliceRoselia/Arceus.jl](https://github.com/AliceRoselia/Arceus.jl). It provides constant-time (`O(1)`) behavior lookup for [Entity-Component-System (ECS)](https://en.wikipedia.org/wiki/Entity_component_system) architectures using trait-based bitmasking.

Arceus bypasses the traditional ECS bottleneck—querying for component combinations—by relying on precomputed bitmask lookups inspired by chess engine optimizations.

---

## Installation

**Latest registered release**:

```julia
julia> ]add Arceus
```

**Development version**:

```julia
julia> ]add https://github.com/Gesee-y/Arceus.jl
```
---

## Principle

**Arceus.jl** is built on a single idea: **precomputed behavior resolution**.

By leveraging either [PEXT bitboards](https://www.chessprogramming.org/BMI2) or magic bitboards, the package maps every possible trait combination to a unique output **at compile-time or initialization**, allowing for direct, constant-time lookups.

This approach is particularly powerful when the number of trait combinations becomes combinatorially large—something that quickly renders traditional `if`/`else` chains unmanageable and slow. Archetype-based ECS designs frequently encounter such branching complexity, e.g., handling conditions like `"if A and B and C"`, `"if A and B and D"` etc.

Instead of resolving these conditions at runtime, **Arceus** precomputes all possible outcomes in advance and performs lookups in under **20 nanoseconds**, even with the slowest (software) backend.

With modern CPUs or when using magic numbers, this latency drops to **7 ns or less**.

---

## Key Features

* **O(1) Trait Lookup**: Ultra-fast behavior dispatch using precomputed lookup tables, powered by [PEXT bitboard](https://www.chessprogramming.org/BMI2) or magic bitboards.
* **Multiple Backends**:

  * Native PEXT (BMI2-enabled CPUs):
  * Software fallback
  * Magic bitboards
* **Trait Pool DSL**: Define and organize traits declaratively, with support for subpools, explicit bit ranges, and dependencies.
* **Persistence**: Magic numbers are cached to disk (CSV), enabling fast and deterministic reinitialization.
* **Composable & Flexible**: Integrates with ECS engines using bitmasking/archetypes and supports fine-grained control over bit layouts.

---

## 🔧 Example Usage

```julia
using Arceus

#Traitpool must be defined at compile time.
println("Checkpoint!")

@traitpool "ABCDEF" begin
    @trait electro
    @trait flame #Defining trait without bits.
    @trait laser at 2 #Defining trait with a specified bit (from the right or least significant.)
    @subpool roles begin
        @trait attacker
        @trait support
        
    end
    @subpool meta at 16-32 begin #Subpool can be defined with a specified number of bits, but for a concrete subpool, the number of bits can be defined.
        @trait earlygame
        @trait midgame
        @trait lategame
    end
    @abstract_subpool reserve1 at 33-48 #Defining start and finish bits.
    @abstract_subpool reserve2 at 8 #Defining the size, but not the sub_trait.
end

#This will register the variable at compile time and construct a trait pool at runtime.
@make_traitpool Pokemon from "ABCDEF" begin
    @trait electro #Creating trait pool with the following traits.
    @trait flame
end

#You can modify and copy trait pools.

@copy_traitpool Pokemon => Pokemon2
@make_traitpool X from "ABCDEF"
@copy_traitpool Pokemon => X
# You can use copy_traitpool to existing trait pools too.

@settraits Pokemon2 begin
    @trait -electro 
    @trait +roles.attacker
    @trait roles.support depends X
    @trait meta.earlygame depends X
end

f1 = @lookup k "ABCDEF" begin
    out = 1.0
    if @hastrait k.electro
        out *= 2
    end
    if @hastrait k.flame
        out *= 1.5 
    end
    if @hastrait k.meta.earlygame
        out *= 1.2
    end
    return out
end

#If the variable is not registered, it is not seen in the module, the result is error finding variable of that name.
@register_variable f1
#We then can finally make the lookup function.
effectiveness = @make_lookup f1
lookup_val = effectiveness[Pokemon]

println(lookup_val)
```

---

## ⚙Performance Summary

| Backend         | Lookup Time | Notes                               |
| --------------- | ----------- | ----------------------------------- |
| Native PEXT     | \~2–3ns     | Requires BMI2 support (recent CPUs) |
| Magic Bitboards | \~7ns       | Hardware-independent; slow to init  |
| Software PEXT   | \~20ns      | Safe fallback for legacy systems    |

At 60 FPS, even the slowest path allows **50,000+ lookups/frame**, and magic numbers go up to **140,000+**. Native PEXT? Up to **500,000 lookups/ms**.

---

## ⚠️ Known Limitations

* **Magic number generation** is compute-intensive the first time but is cached afterward.
* **No dynamic function generation**, which avoids memory leaks tied to Julia’s compilation model.

---

## 🤝 Contributing

Pull requests and issues are welcome. Any improvement—performance, documentation, features—is appreciated.

Special thanks to [AliceRoselia](https://github.com/AliceRoselia), original author of *Arceus.jl*.

---

## 📝 License

This project is licensed under the MIT License, as defined by the original repository.
