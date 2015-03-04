{-|
  Module      : $Header$
  Copyright   : (c) 2014 Edward O'Callaghan
  License     : LGPL-2.1
  Maintainer  : eocallaghan@alterapraxis.com
  Stability   : provisional
  Portability : portable

  This module encapsulates Synchronous data transmission and reception
 
  This group of functions presents synchronous, blocking calls (with optional
  timeouts) for transmitting and receiving samples.
 
  The synchronous interface is built atop the asynchronous interface, and is
  generally less complex and easier to work with.  It alleviates the need to
  explicitly spawn threads (it is done under the hood) and manually manage
  sample buffers.
 
  Under the hood, this interface spawns worker threads to handle an
  asynchronous stream and perform thread-safe buffer management.
-}

module LibBladeRF.Sync ( bladeRFSyncConfig
                       , bladeRFSyncTx
                       , bladeRFSyncRx
                       ) where

import Foreign
import Foreign.C.Types
import Foreign.C.String

import qualified Data.ByteString as BS

import Bindings.LibBladeRF
import LibBladeRF.LibBladeRF
import LibBladeRF.Types


-- | (Re)Configure a device for synchronous transmission or reception
bladeRFSyncConfig :: DeviceHandle  -- ^ Device handle
                  -> BladeRFModule -- ^ Module to use with synchronous interface
                  -> BladeRFFormat -- ^ Format to use in synchronous data transfers
                  -> Int           -- ^ The number of buffers to use in the underlying data stream.
                  -> Int           -- ^ The size of the underlying stream buffers, in samples. This value must be a multiple of 1024.
                  -> Int           -- ^ The number of active USB transfers that may be in-flight at any given time.
                  -> Int           -- ^ Timeout (milliseconds) for transfers in the underlying data stream.
                  -> IO ()

bladeRFSyncConfig dev m f nb sz tr to = do
  c'bladerf_sync_config (unDeviceHandle dev) ((fromIntegral . fromEnum) m) ((fromIntegral . fromEnum) f) (fromIntegral nb) (fromIntegral sz) (fromIntegral tr) (fromIntegral to)
  return () -- ignores ret

-- | Transmit IQ samples.
--
-- Under the hood, this call starts up an underlying asynchronous stream as
-- needed. This stream can be stopped by disabling the TX module. (See
-- bladeRFEnableModule for more details.)
--
-- Samples will only be sent to the FPGA when a buffer have been filled. The
-- number of samples required to fill a buffer corresponds to the `buffer_size`
-- parameter passed to bladeRFSyncConfig.
bladeRFSyncTx :: DeviceHandle    -- ^ Device handle
              -> BS.ByteString   -- ^ Array of samples
              -> Int             -- ^ Number of samples to write
              -> BladeRFMetadata -- ^ Sample metadata. This must be provided when using
                                 --   the ::BLADERF_FORMAT_SC16_Q11_META format, but may
                                 --   be NULL when the interface is configured for
                                 --   the ::BLADERF_FORMAT_SC16_Q11 format.
              -> Int             -- ^ Timeout (milliseconds) for this call to complete. Zero implies infinite.
              -> IO ()
bladeRFSyncTx dev s n md t = do
  pmd <- malloc :: IO (Ptr C'bladerf_metadata)
-- Use the following instead when switching to ghc7.8 later..
-- bladeRFMetadataToCBladeRFMetadata :: BladeRFMetadata -> C'bladerf_metadata
  let meta = C'bladerf_metadata { c'bladerf_metadata'timestamp    = timestamp md
                                , c'bladerf_metadata'flags        = flags     md
                                , c'bladerf_metadata'status       = status    md
                                , c'bladerf_metadata'actual_count = (fromIntegral . count) md
                                , c'bladerf_metadata'reserved     = [0]
                                }
  poke pmd meta
  BS.useAsCStringLen s $
    \(p, _len) -> c'bladerf_sync_tx (unDeviceHandle dev) p (fromIntegral n) pmd (fromIntegral t)
  free pmd

-- | Receive IQ samples.
--
-- Underthe hood, this call starts up an underlying asynchronous stream as
-- needed. This stream can be stopped by disabling the RX module. (See
-- bladeRFEnableModule for more details.)
bladeRFSyncRx :: DeviceHandle    -- ^ Device handle
              -> Int             -- ^ Number of samples to read
              -> Int             -- ^ Timeout (milliseconds) for this call to complete. Zero implies infinite.
              -> IO (BS.ByteString, BladeRFMetadata)
bladeRFSyncRx dev n t = do
  pmd <- malloc :: IO (Ptr C'bladerf_metadata)
  ptr <- mallocBytes (4 * n)
  c'bladerf_sync_rx (unDeviceHandle dev) ptr (fromIntegral n) pmd (fromIntegral t)
  par <- peekArray (4 * n) ptr
  let bs = BS.pack par
  cmd <- peek pmd
 -- Use the following instead when switching to ghc7.8 later..
 -- bladeRFMetadataFromCBladeRFMetadata :: C'bladerf_metadata -> BladeRFMetadata 
  let meta = BladeRFMetadata { timestamp = c'bladerf_metadata'timestamp    cmd
                             , flags     = c'bladerf_metadata'flags        cmd
                             , status    = c'bladerf_metadata'status       cmd
                             , count     = fromIntegral $ c'bladerf_metadata'actual_count cmd
                             }
  free pmd
  return (bs, meta)