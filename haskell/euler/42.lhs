The nth term of the sequence of triangle numbers is given by, tn =
½n(n+1); so the first ten triangle numbers are:

1, 3, 6, 10, 15, 21, 28, 36, 45, 55, ...

By converting each letter in a word to a number corresponding to its
alphabetical position and adding these values we form a word
value. For example, the word value for SKY is 19 + 11 + 25 = 55 =
t10. If the word value is a triangle number then we shall call the
word a triangle word.

Using words.txt (right click and 'Save Link/Target As...'), a 16K text
file containing nearly two-thousand common English words, how many are
triangle words?

> import Data.List.Ordered (member)
> import qualified Data.ByteString.Lazy.Char8 as BL

> first_ten = [1, 3, 6, 10, 15, 21, 28, 36, 45, 55]

> triangle :: Integer -> Integer
> triangle n = let n' = fromInteger n in truncate $ n' / 2 * (n'+1)

Make a list of all of the triangular words.

> triangles = map triangle [1..]

Add up the letter values in a word.

> word_value :: String -> Integer
> word_value = toInteger . foldr (\l s -> (1 + fromEnum l - fromEnum 'A') + s) 0

A word is a triangle if the value is in my list of triangle numbers.
This is using member from Data.List.Ordered which has the nice
property of stopping if you get past the word's value.

> word_is_triangle w = let v = word_value w in member v triangles

How many words are triangular?

> count_triangles = (length.filter word_is_triangle)

> euler_42 = do
>   d <- BL.readFile "p042_words.txt"
>   print $ count_triangles $ read $ "[" ++ (BL.unpack d) ++ "]"
