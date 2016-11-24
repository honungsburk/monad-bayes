{-|
Module      : Control.Monad.Bayes.Coprimitive
Description : Coprimitive probability monad and density functions
Copyright   : (c) Yufei Cai, 2016
              (c) Adam Scibior, 2016
License     : MIT
Maintainer  : ams240@cam.ac.uk
Stability   : experimental
Portability : GHC

-}

{-# LANGUAGE
  GADTs,
  DeriveFunctor
   #-}

module Control.Monad.Bayes.Coprimitive (
  AwaitSampler (AwaitSampler),
  Coprimitive (Coprimitive),
  runCoprimitive
) where

import Control.Monad.Trans.Class
import Control.Monad.Coroutine
import Control.Monad.Coroutine.SuspensionFunctors
import Data.Maybe

import Control.Monad.Bayes.LogDomain
import Control.Monad.Bayes.Primitive
import Control.Monad.Bayes.Class
import Control.Monad.Bayes.Weighted
import Control.Monad.Bayes.Deterministic

-- | Suspension functor: yields primitive distribution, awaits sample.
data AwaitSampler r y where
  AwaitSampler :: Primitive r a -> (a -> y) -> AwaitSampler r y
deriving instance Functor (AwaitSampler r)

-- | Pause probabilistic program whenever a primitive distribution is
-- encountered, yield the encountered primitive distribution, and
-- await a sample of that primitive distribution.
newtype Coprimitive m a = Coprimitive
  { runCoprimitive :: Coroutine (AwaitSampler (CustomReal m)) m a
  }
  deriving (Functor, Applicative, Monad)

type instance CustomReal (Coprimitive m) = CustomReal m

instance MonadTrans Coprimitive where
  lift = Coprimitive . lift

instance (MonadDist m) => MonadDist (Coprimitive m) where
  primitive d = Coprimitive (suspend (AwaitSampler d return))

instance (MonadBayes m) => MonadBayes (Coprimitive m) where
  factor = lift . factor
