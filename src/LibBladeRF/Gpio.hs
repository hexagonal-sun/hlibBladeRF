{-|
  Module      : $Header$
  Copyright   : (c) 2014 Edward O'Callaghan
  License     : LGPL-2.1
  Maintainer  : eocallaghan@alterapraxis.com
  Stability   : provisional
  Portability : portable

  This module GPIO configuration handling
-}

module LibBladeRF.Gpio ( bladeRFConfigGPIORead
                       , bladeRFConfigGPIOWrite
                       ) where

import Foreign
import Foreign.C.Types
import Foreign.C.String

import Bindings.LibBladeRF
import LibBladeRF.LibBladeRF
import LibBladeRF.Types


-- | Read a configuration GPIO register
bladeRFConfigGPIORead :: DeviceHandle -- ^ Device handle
                      -> IO Word32    -- ^ Read data
bladeRFConfigGPIORead dev = do
  pv <- malloc :: IO (Ptr Word32)
  c'bladerf_config_gpio_read (unDeviceHandle dev) pv
  v <- peek pv
  free pv
  return v

-- | Write a configuration GPIO register. Callers should be sure to perform a
--
--   read-modify-write sequence to avoid accidentally clearing other
--   GPIO bits that may be set by the library internally.
bladeRFConfigGPIOWrite :: DeviceHandle -- ^ Device handle
                       -> Word32       -- ^ Data to write to GPIO register
                       -> IO ()
bladeRFConfigGPIOWrite dev v = do
  c'bladerf_config_gpio_write (unDeviceHandle dev) v
  return () -- ignores ret