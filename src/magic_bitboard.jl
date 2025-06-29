using Random

"""
    struct MagicBitboard 
        value::UInt
        magic::UInt
        shift::UInt

This struct represents a magic bitboard, used to accelerate lookup for entities.
"""
struct MagicBitboard 
    value::UInt
    magic::UInt
    shift::UInt
end

struct maskedBitsIterator
    mask::UInt64
    reverse_mask::UInt64
    maskedBitsIterator(mask::UInt64) = new(mask,~mask)
    maskedBitsIterator(mask) = maskedBitsIterator(UInt64(mask))
end
Base.iterate(::maskedBitsIterator) = UInt64(0),UInt64(0)

function Base.iterate(X::maskedBitsIterator, state)
    ans = X.mask&((state|X.reverse_mask)+1)

    return ifelse(ans==0, nothing, (ans,ans))
end

function use_magic_bitboard(arr::AbstractVector, mask::UInt64, magic::UInt64, shift::Integer, query::UInt64)
    return @inbounds arr[get_lookup_index(mask, magic, shift, query)]
end

function get_lookup_index(mask::UInt64, magic::UInt64, shift::Integer, query::UInt64)
    return (((query&mask)*magic)>>shift)+1
end

struct DONTCARE end;



"
returns the last number which needs to be checked.
This loops from zero to that number. zero magic number, however, yields trivial result mapping all to the same value, and thus not need to be checked.
"
function magic_bitboard_range(mask)
    #The last bit represents its 
    Big_interval=Int128(2)^64
    
    return UInt64(div(Big_interval,(mask&-mask))-1)
end

function verify_magic_bitboard(answer_table,magic::UInt64, shift, return_type::Type)
    #println("Verifying magic", magic)
    A = Vector{Union{return_type, DONTCARE}}(undef, 1<<(64-shift))
    for i in eachindex(A)
        A[i]= DONTCARE()
    end
    for (traits, ans) in answer_table
        index = ((traits*magic)>>shift)+1
        if (A[index] === DONTCARE())
            A[index] = ans
        elseif (A[index] != ans)
            return false
        end
    end
    return true
end


function find_magic_bitboard(mask::UInt64, f, return_type::Type = Any; shift_minimum::Integer = 32, guess_limits::Integer=1000000, rng = Random.TaskLocalRNG())
    answer_table = Dict{UInt64, return_type}()
    #We get a hash table but not a perfect one so we need to do it again.
    for i in maskedBitsIterator(mask)
        Temp::Union{return_type, DONTCARE} = f(i)
        if Temp !== DONTCARE()
            answer_table[i] = Temp
        end
    end
    answer_table = collect(answer_table)
    #Now, we need to find the perfect hash that solves this answer table.
    #Can change if needed.
    initial_shift = shift = 48
    limit = guess_limits
    guess = UInt64(0)
    while !(verify_magic_bitboard(answer_table, guess, shift, return_type))
        guess = rand(rng,UInt64)&rand(rng,UInt64)&rand(rng,UInt64)
        limit -= 1
        if (limit <= 0)
            shift -= 1
            if (shift < shift_minimum)
                error("Cannot find magic bitboard with sufficiently small size (indicated by shift_minimum).")
            end
            limit = guess_limits
        end
    end
    answer_guess = guess
    answer_shift = shift
    if (shift == initial_shift)
        trying_to_shrink = true
        while trying_to_shrink
            answer_guess = guess
            answer_shift = shift
            shift += 1
            limit = guess_limits
            if (shift >= 64)
                break
            end
            limit = guess_limits
            while !(verify_magic_bitboard(answer_table, guess, shift, return_type))
                guess = rand(rng,UInt64)&rand(rng,UInt64)&rand(rng,UInt64)
                limit -= 1
                if (limit <= 0)
                    trying_to_shrink = false
                    break
                end
            end
        end
    end

    return answer_guess, answer_shift
    #You can construct later.
end

function fill_magic_bitboard(mask::UInt64,magic, f, return_type::Type, shift)
    A = Vector{return_type}(undef, 1<<(64-shift))
    answer_table = Dict{UInt64, return_type}()
    for traits in maskedBitsIterator(mask)
        Temp::Union{return_type, DONTCARE} = f(traits)
        if Temp !== DONTCARE()
            ans = Temp
            index = ((traits*magic)>>shift)
            A[begin+index] = ans
        end
    end
    
    return A
end