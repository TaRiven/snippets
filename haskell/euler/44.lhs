Pentagonal numbers are generated by the formula, Pn=n(3n−1)/2. The
first ten pentagonal numbers are:

1, 5, 12, 22, 35, 51, 70, 92, 117, 145, ...

It can be seen that P4 + P7 = 22 + 70 = 92 = P8. However, their
difference, 70 − 22 = 48, is not pentagonal.

Find the pair of pentagonal numbers, Pj and Pk, for which their sum
and difference are pentagonal and D = |Pk − Pj| is minimised; what is
the value of D?


> import qualified Data.Set as Set
> import Control.Concurrent.Async

> first_ten = [1, 5, 12, 22, 35, 51, 70, 92, 117, 145]

> pentagonal :: Integer -> Integer
> pentagonal n = let n' = fromInteger n in truncate $ n' * (3 * n' - 1) / 2

> pentagons = Set.fromList $ map pentagonal [1..1000000]

> is_pentagonal = (flip Set.member) pentagons

> interesting_pair a b = is_pentagonal (a + b) && is_pentagonal (abs (b - a))

> look_around' n = filter (uncurry interesting_pair) $ zip p $ drop n p
>   where p = Set.toList pentagons

> look_around = (fmap.filter) (/= []) $ mapConcurrently (($!) return . look_around') [1000..5000]

This found the answer as 5482660 (1560090,7042750) -- but it took a
few minutes.  It's significantly faster when built on the commandline:

ghc -threaded -O2 44.lhs
 ./44 +RTS -N

> main = look_around >>= print
