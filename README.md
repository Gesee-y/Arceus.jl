# Arceus.jl

A fork of [AliceRoselia](https://github.com/AliceRoselia/Arceus.jl)'s *Arceus*, an entity management system based on magic bitboards.

[Entity-Component-System (ECS)](https://en.wikipedia.org/wiki/Entity_component_system) is a well-established architecture for managing entities by decoupling **data** (components) from **behavior** (systems). However, traditional ECS approaches suffer from query-based bottlenecks—retrieving all entities with a specific set of components can become redundant and slow, especially as the number of possible component combinations grows.

**Arceus.jl** solves this using an approach inspired by [magic bitboards](https://www.chessprogramming.org/Magic_Bitboards)—a technique originally used in chess engines to precompute move lookups. With it, Arceus offers lightning-fast, constant-time (`O(1)`) behavior resolution for any component combination.

## Installation

**Stable version**

```julia
julia> ]add Arceus
```

**Development version**

```julia
julia> ]add https://github.com/Gesee-y/Arceus.jl
```

## Features

* **Constant-Time Behavior Lookup**
  Precompute all possible behaviors for entities and retrieve them instantly based on their components.

* **Caching of Magic Numbers**
  Magic numbers used for lookups are cached to disk (CSV), ensuring deterministic, reproducible, and fast reinitialization.

* **Compatibility**
  Works with any archetype-based ECS using bitmasking or similar approaches for component storage.

* **Fine-Grained Bit Manipulation**
  Define custom bit ranges for component pools, explicitly control trait positions, and encode trait dependencies.

## Example

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

#Subpool also must be defined in the global scope.
@subpool "Biome" "ABCDEF".reserve1.biome_preference begin
    @trait beach_preference
    @trait ice_preference
    @trait volcanic_preference
end
#Defining concrete subpool. 
@subpool "Meta" "ABCDEF".meta

@make_subpool "Biome" biometraits Pokemon
@make_subpool "Meta" metatraits Pokemon
@make_subpool "Biome" biometraits2 begin
    @trait beach_preference 1
    @trait ice_preference 0
    @trait volcanic_preference
end

#This "registers" subpool.
#Usage...
function x(biometraits3::get_trait_pool_type("Biome"))
    @register_subpool "Biome" biometraits3 #Since this is a subpool.
    #Use @register_traitpool for a non-subpool trait pool.
end

#This joins the subpools to their parent traitpool (Presume parent, otherwise they write whatever bits they happen to occupy).
#This syntax is used for the sake of consistent syntax across the entire package.
@join_subpools Pokemon begin
    @subpool biometraits2
    @subpool metatraits
end

#You can modify and copy trait pools.

@copy_traitpool Pokemon Pokemon2
@copy_traitpool Pokemon Pokemon3
@copy_traitpool Pokemon Pokemon4
@make_traitpool "ABCDEF" X
@copy_traitpool Pokemon X
# You can use copy_traitpool to existing trait pools too.

@settraits Pokemon2 begin
    @trait -electro 
    @trait +roles.attacker
    @trait roles.support depends X
    @trait meta.earlygame depends X
end

@addtraits Pokemon3 begin
    @trait electro 
    @trait roles.attacker
    @trait roles.support depends X 
    @trait meta.earlygame depends X
end

@removetraits Pokemon4 begin
    @trait electro 
    @trait roles.attacker
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

## Known Limitations

* Generating the magic numbers for the first time is compute-intensive. However, this is a one-time cost, as results are cached for future runs.

## Contributions

All contributions are welcome! Feel free to submit pull requests or open issues.

And don't forget to support the original author of this system, [AliceRoselia](https://github.com/AliceRoselia).

## License

This package is on the MIT License, as set by its original author.
