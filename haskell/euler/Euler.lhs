As I've been going through various euler things, I've noticed I've
been copying and pasting a bunch of code around.  I decided to make a
euler module that contains the stuff I've been copying and pasting.

> module Euler where


digitsb takes an integer and returns a list of the digits of that
integer in base b.

> digitsb :: Int -> Integer -> [Int]
> digitsb _ 0 = []
> digitsb b n = reverse $ go n
>   where go :: Integer -> [Int]
>         go 0 = []
>         go x = let (a, r) = x `divMod` (toEnum b) in (fromEnum r) : go a

digits is a base 10 version of digitsb.  Several of the euler puzzles
so far have needed the digits in base 10, so that's a first class
function here.  e.g., 123 -> [1, 2, 3]

> digits = digitsb 10

undigits is just the opposite of digits.  e.g., [1, 2, 3] -> 123

> undigits :: (Enum a, Num a) => [Int] -> a
> undigits = foldl (\b x -> b * 10 + (toEnum x)) 0

There are also quite a lot of puzzles that use prime numbers.

> isPrime :: Integer -> Bool
> isPrime n
>   | n < 2 = False
>   | otherwise = not $ any (\x -> n `mod` x == 0) $ takeWhile (\c -> c^2 <= n) primes

Then a list of all primes:

> primes :: [Integer]
> primes = 2:[x | x <- [3,5..], isPrime x]
