# Arceus.jl
Arcane entity management system based on magic bitboard.

Documentation can be found in the test folder. 

Ok, I will see how I can optimize this (gonna be a long fight)

first understanding what a magic bitboard is.

it seems to be some sort of chess game optimisation. each bits represent a square in the game, we can create pools and lookup table (something like a hash table) using that bitboard to know exactly where to look for some entity.
lemme check the code again 