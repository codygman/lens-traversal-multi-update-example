{-# LANGUAGE TemplateHaskell #-}
module Main where

import Control.Lens

data A = A { _afoo :: String
           , _abar :: String
           } deriving Show
makeLenses ''A

data B = B { _foo :: String
           , _bar :: String
           , _stuff :: [A]
           } deriving Show

makeLenses ''B

exB = B { _foo = "foo"
        , _bar = "bar"
        , _stuff = [ (A {_afoo = "foo", _abar = "bar"}) ]
        }

{-
both :: Traversal' (a, a) a
both f = \(a1, a2) -> (,) <$> f a1 <*> f a2
-}
oneFoo :: Traversal' B String
oneFoo = stuff . traverse . afoo

{-
desired usage:
λ> exB
B {_foo = "foo", _bar = "bar", _stuff = [A {_afoo = "foo", _abar = "bar"}]}
λ> exB & allFoos .~ "updatedFoo"
B {_foo = "updatedFoo", _bar = "bar", _stuff = [A {_afoo = "updatedFoo", _abar = "bar"}]}
-}
allFoos :: Traversal' B String
allFoos f (B fooVar barVar stuffVar) = B <$> f fooVar <*> pure barVar <*> (traverse . afoo) f stuffVar
-- ((traverse . afoo) f) -- (traverse . afoo $ f) -- (f (stuffVar ^. traverse . afoo))

{-
[00:35] <nshepperd> codygman________: f is 'String -> g String', but you want g [A]
[00:36] <nshepperd> codygman________: in the last argument of <*> there
[00:38] <nshepperd> codygman________: however, you have a function that will turn 'String -> g String' into '[A] -> g [A]', namely traverse . afoo
[00:48] <codygman________> nshepperd: I'm not quite figuring out how to apply traverse to my current problem. That last argument, the first thing I tried cahnging it to was "(traverse f (stuffVar ^. traverse . afoo))"
[00:49] == eliaslfox [~eliaslfox@fixed-187-189-217-231.totalplay.net] has quit [Remote host closed the connection]
[00:50] <nshepperd> codygman________: check this out: the type of (traverse . afoo) is 'Traversal [A] String', right? or, (String -> g String) -> ([A] -> g [A])
[00:50] <nshepperd> then the type of (traverse . afoo) f is [A] -> g [A]
[00:51] <nshepperd> which is just what you want!
[00:48] <codygman________> nshepperd: I'm not quite figuring out how to apply traverse to my current problem. That last argument, the first thing I tried cahnging it to was "(traverse f (stuffVar ^. traverse . afoo))"
[00:49] == eliaslfox [~eliaslfox@fixed-187-189-217-231.totalplay.net] has quit [Remote host closed the connection]
[00:50] <nshepperd> codygman________: check this out: the type of (traverse . afoo) is 'Traversal [A] String', right? or, (String -> g String) -> ([A] -> g [A])
[00:50] <nshepperd> then the type of (traverse . afoo) f is [A] -> g [A]
[00:50] <xacktm> pangwa: what type is PortNumber?  there are lots of fromJSON instances as well, e.g. https://stackoverflow.com/questions/7278130/aeson-fromjson-instance#7279565
[00:50] <nshepperd> then the type of (traverse . afoo) f stuffVar is g [A]
[00:51] <nshepperd> which is just what you want!
[00:51] == sqooq [~cypress@96.58.47.10] has joined #haskell
[00:52] <pangwa> it's a constructor of PortID in the network package. https://hackage.haskell.org/package/network-2.6.3.4/docs/Network.html#t:PortNumber
[00:52] == dfeuer [~dfeuer@wikimedia/Dfeuer] has joined #haskell
[00:53] <pangwa> I want parse an number field as PortNumber
[00:54] <xacktm> pangwa: how about fromInteger? https://hackage.haskell.org/package/network-2.6.3.4/docs/Network.html#v:fromInteger
[00:54] == davr0s [~textual@host86-165-118-39.range86-165.btcentralplus.com] has joined #haskell
[00:56] <pangwa> cool! it works! thanks @xacktm ..
[00:56] <xacktm> welcome
[00:56] == oish [~charlie@159.22.169.217.in-addr.arpa] has joined #haskell
[00:56] == mercerist [~mercerist@5ED2D202.cm-7-3d.dynamic.ziggo.nl] has joined #haskell
[00:56] == antsanto [~antsanto@171.76.58.58] has quit [Remote host closed the connection]
[00:56] <nshepperd> codygman________: (^.) isn't normally used in this case, because (^.) takes out the thing pointed by the lens and forgets the context (how to create a new A with the modified value)
[00:57] <pangwa> I'm just making a port of persistent-mysql to persistent-mysql-haskell (to use mysql-haskell). it now works..
[00:57] == takuan [~takuan@178-116-225-94.access.telenet.be] has quit [Remote host closed the connection]
[00:58] <codygman________> nshepperd: I'm still not getting it, perhaps I need some sleep :) Here were my attempts: allFoos f (B fooVar barVar stuffVar) = B <$> f fooVar <*> pure barVar <*> ((traverse . afoo) f) -- (traverse . afoo $ f) -- (f (stuffVar ^. traverse . afoo))
[00:58] <nshepperd> codygman________: try this: '(traverse . afoo) f stuffVar'
[00:59] == path[l] [~vsi@c-73-189-43-89.hsd1.ca.comcast.net] has quit [Quit: path[l]]
[01:01] <codygman________> nshepperd: You've made part of my Saturday plans reading back over this chat log and figuring out why that works. Thanks! :)
-}

{-
λ> :r
[1 of 1] Compiling Main             ( /home/cody/traversal-example/src/Main.hs, interpreted )

/home/cody/traversal-example/src/Main.hs:38:76-106: error:
    • Couldn't match type ‘Char’ with ‘A’
      Expected type: f [A]
        Actual type: f String
    • In the second argument of ‘(<*>)’, namely
        ‘(f (stuffVar ^. traverse . afoo))’
      In the expression:
        B <$> f fooVar <*> pure barVar
          <*> (f (stuffVar ^. traverse . afoo))
      In an equation for ‘allFoos’:
          allFoos f (B fooVar barVar stuffVar)
            = B <$> f fooVar <*> pure barVar
                <*> (f (stuffVar ^. traverse . afoo))
   |
38 | allFoos f (B fooVar barVar stuffVar) = B <$> f fooVar <*> pure barVar <*> (f (stuffVar ^. traverse . afoo))
   |                                                                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Failed, no modules loaded.
-}


main :: IO ()
main = do
  putStrLn "hello world"
