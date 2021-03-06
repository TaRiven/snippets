
-- Simple prime implementation
isPrime :: Integer -> Bool

isPrime 0 = False
isPrime 1 = False
isPrime 2 = True
isPrime x
	| even(x)   = False
	| otherwise = rprime 3
	where rprime a
		| (a ^ 2) > x    = True
		| mod x a == 0   = False
		| otherwise      = rprime (a + 2)

-- The above implementation was used to create the list of the first 100
-- primes for bootstrapping this list the following way:
-- take 100 [ x | x <- [0..], isPrime(x)]
primes = [2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,
			89,97,101,103,107,109,113,127,131,137,139,149,151,157,163,167,173,
			179,181,191,193,197,199,211,223,227,229,233,239,241,251,257,263,
			269,271,277,281,283,293,307,311,313,317,331,337,347,349,353,359,
			367,373,379,383,389,397,401,409,419,421,431,433,439,443,449,457,
			461,463,467,479,487,491,499,503,509,521,523]
				++ [ x | x <- [541..], isPrime2(x) ]

-- A version of isPrime that uses the above list.
isPrime2 :: Integer -> Bool

isPrime2 0 = False
isPrime2 1 = False
isPrime2 a = rprime(primes)
	where rprime(x:xs)
		| x == a       = True        -- Matching prime
		| (x ^ 2) > a  = True        -- Only do up to the square root
		| mod a x == 0 = False       -- composite if divisible
		| otherwise    = rprime(xs)  -- Recurse

-- Print out the hundred thousandth prime
-- main = putStr(show (primes !! 100000) ++ "\n")

primeBetween :: Integer -> Integer -> Integer

-- Find the next prime greater than the number in the middle of these
primeBetween a b = [ x | x <- primes ,
						x >= (a +
							(truncate(fromIntegral(b - a)/2))::Integer) ] !! 0


-- This one works a lot better
primeBetween2 :: Integer -> Integer -> Integer
primeBetween2 a b = [ x |
						x <- [(a+(truncate(fromIntegral(b - a)/2))::Integer)..],
						isPrime2(x) ] !! 0

primeNearest :: Integer -> Integer
primeNearest a
	| isPrime2(a) = a
	| a < 2 = 2
	| mod a 2 == 0 = primeNearest (a + 1)
	| otherwise = primeNearestHelper(2)
	where primeNearestHelper(x)
		| a > 0 && isPrime2(a - x) = a - x
		| isPrime2(a + x) = a + x
		| otherwise = primeNearestHelper(x + 2)

primeBetween3 :: Integer -> Integer -> Integer
primeBetween3 a b = primeNearest(a+(truncate(fromIntegral(b - a)/2))::Integer)

-- Use div instead of truncate/fromIntegral/cast for integer division
primeBetween4 :: Integer -> Integer -> Integer
primeBetween4 a b = primeNearest(a+((b - a) `div` 2))

-- Create a list of the primes that are furthest away from powers of two

powersOfTwo = [ 2 ^ x | x <- [1..32]]

primeBetweenRange :: [Integer] -> [Integer]
primeBetweenRange(x:xs)
	| xs == [] = xs
	| otherwise = [ primeBetween3 x (xs !! 0) ] ++ primeBetweenRange(xs)

