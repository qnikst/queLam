{-# LANGUAGE DataKinds              #-}
{-# LANGUAGE FlexibleContexts       #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses  #-}
{-# LANGUAGE RankNTypes             #-}
{-# LANGUAGE ScopedTypeVariables    #-}
{-# LANGUAGE TypeFamilies           #-}
{-# LANGUAGE TypeOperators          #-}
module QueLam.Core where

import           Data.Proxy
import           GHC.TypeLits
import           SuperRecord

-- Implementation of Suzuki, Kiselyov and Kameyama paper

infix 5 =%
infixl 2 @%
infixl 8 .%
infixr 2 &%
infixl 7 *%

class Symantics repr where
  type Obs repr :: * -> *
  type Handle repr (schema :: [(Symbol, [*])]) :: *
  int    :: Int    -> repr schema Int
  bool   :: Bool   -> repr schema Bool
  string :: String -> repr schema String
  lam    :: (repr schema a -> repr schema b) -> repr schema (a -> b)
  ($$)   :: repr schema (a -> b) -> repr schema a -> repr schema b
  for    :: repr schema [a] -> (repr schema a -> repr schema [b]) -> repr schema [b]
  where' :: repr schema Bool -> repr schema [a] -> repr schema [a]
  yield  :: repr schema a -> repr schema [a]
  nil    :: repr schema [a]
  (@%)   :: repr schema [a] -> repr schema [a] -> repr schema [a]
  (=%)   :: Eq a => repr schema a -> repr schema a -> repr schema Bool
  (*%)   :: Num a => repr schema a -> repr schema a -> repr schema a
  (.%)   :: Has l rs t => repr schema (Rec rs) -> FldProxy l -> repr schema t
  rnil'  :: repr schema (Rec '[])
  (&%)   ::
    ( RecSize flds ~ s
    , sortedFlds ~ Sort ((l := t) ': flds)
    , KnownNat s
    , KnownNat (RecVecIdxPos l sortedFlds)
    , KeyDoesNotExist l flds
    , RecCopy flds flds sortedFlds) =>
    (l := repr schema t) -> repr schema (Rec flds) -> repr schema (Rec sortedFlds)
  table  :: Has t schema r => Handle repr schema -> FldProxy t -> repr schema [Record r]
  observe :: repr schema a -> Obs repr a

compose :: Symantics repr => repr schema ((a -> [b]) -> (b -> [c]) -> (a -> [c]))
compose = lam $ \q -> lam $ \r -> lam $ \x -> for (q $$ x) $ \y -> r $$ y
