{-|
  Module      : $Header$
  Copyright   : (c) 2014 Edward O'Callaghan
  License     : LGPL-2.1
  Maintainer  : eocallaghan@alterapraxis.com
  Stability   : provisional
  Portability : portable

  This module encapsulates types libbladeRF library functions.
-}

module LibBladeRF.Types ( BladeRFVersion(..)
                        , BladeRFDeviceInfo(..)
                        , BladeRFFPGASize(..)
                        , BladeRFBackend(..)
                        , BladeRFRationalRate(..)
                        , BladeRFModule(..)
                        , BladeRFFormat(..)
                        , BladeRFLNAGain(..)
                        , BladeRFVGAGainBounds(..)
                        ) where


import Bindings.LibBladeRF

import Foreign
import Foreign.C.Types
import Foreign.C.String
import Data.Maybe
import Data.Tuple

--
-- | Version structure for FPGA, firmware, libbladeRF, and associated utilities
data BladeRFVersion = BladeRFVersion { major :: Word16 -- ^ Major version
                                     , minor :: Word16 -- ^ Minor version
                                     , patch :: Word16 -- ^ Patch version
                                     , descr :: String -- ^ Version string with any additional suffix information.
                                     } deriving (Eq)

instance Show BladeRFVersion where
  show a = show (major a) ++ "." ++
           show (minor a) ++ "." ++
           show (patch a) ++ " (" ++
                descr a ++ ")"

--
-- | Information about a bladeRF attached to the system
data BladeRFDeviceInfo = BladeRFDeviceInfo { backend :: BladeRFBackend -- ^ Backend to use when connecting to device
                                           , serial  :: String         -- ^ Device serial number string
                                           , usbBus  :: Word8          -- ^ Bus # device is attached to
                                           , usbAddr :: Word8          -- ^ Device address on bus
                                           , inst    :: CUInt          -- ^ Device instance or ID
                                           } deriving (Eq)

instance Show BladeRFDeviceInfo where
  show a = " Backend : " ++ show (backend a) ++ "\n" ++
           " Serial #: " ++ serial a ++ "\n" ++
           " USB bus: " ++ show (usbBus a) ++ "\n" ++
           " USB address: " ++ show (usbAddr a) ++ "\n" ++
           " Instance: " ++ show (inst a)

--
-- | FPGA device variant (size)
data BladeRFFPGASize = FPGA_UNKNOWN -- ^ Unable to determine FPGA variant
                     | FPGA_40KLE   -- ^ 40 kLE FPGA
                     | FPGA_115KLE  -- ^ 115 kLE FPGA
                     deriving (Eq)

instance Show BladeRFFPGASize where
  show FPGA_UNKNOWN = "Unable to determine FPGA variant"
  show FPGA_40KLE   = "40 kLE FPGA"
  show FPGA_115KLE  = "115 kLE FPGA"

instance Enum BladeRFFPGASize where
  fromEnum = fromJust . flip lookup sizes
  toEnum   = fromJust . flip lookup (map swap sizes)

sizes = [ (FPGA_UNKNOWN, c'BLADERF_FPGA_UNKNOWN)
        , (FPGA_40KLE, c'BLADERF_FPGA_40KLE)
        , (FPGA_115KLE, c'BLADERF_FPGA_115KLE)
        ]

-- | Backend by which the host communicates with the device
data BladeRFBackend = BACKEND_ANY     -- ^ Don't Care, use any available backend
                    | BACKEND_LINUX   -- ^ Linux kernel driver
                    | BACKEND_LIBUSB  -- ^ libusb
                    | BACKEND_CYPRESS -- ^ CyAPI
                    | BACKEND_DUMMY   -- ^ Dummy used for development purposes
                    deriving (Eq)

instance Show BladeRFBackend where
  show BACKEND_ANY     = "Don't Care, use any available backend"
  show BACKEND_LINUX   = "Linux kernel driver"
  show BACKEND_LIBUSB  = "libusb"
  show BACKEND_CYPRESS = "CyAPI"
  show BACKEND_DUMMY   = "Dummy used for development purposes"

instance Enum BladeRFBackend where
  fromEnum = fromJust . flip lookup backends
  toEnum   = fromJust . flip lookup (map swap backends)

backends = [ (BACKEND_ANY, c'BLADERF_BACKEND_ANY)
           , (BACKEND_LINUX, c'BLADERF_BACKEND_LINUX)
           , (BACKEND_LIBUSB, c'BLADERF_BACKEND_LIBUSB)
           , (BACKEND_CYPRESS, c'BLADERF_BACKEND_CYPRESS)
           , (BACKEND_DUMMY, c'BLADERF_BACKEND_DUMMY)
           ]

-- | Rational sample rate representation
data BladeRFRationalRate = BladeRFRationalRate { integer :: Word64 -- ^ Integer portion
                                               , num     :: Word64 -- ^ Numerator in fractional portion
                                               , den     :: Word64 -- ^ Denominator in fractional portion. This must be > 0.
                                               } deriving (Eq, Show)


-- | Module selection for those which have both RX and TX constituents
data BladeRFModule = MODULE_RX -- ^ Receive Module
                   | MODULE_TX -- ^ Transmit Module
                   deriving (Eq)

instance Enum BladeRFModule where
  fromEnum = fromJust . flip lookup modules
  toEnum   = fromJust . flip lookup (map swap modules)

modules = [ (MODULE_RX, c'BLADERF_MODULE_RX)
          , (MODULE_TX, c'BLADERF_MODULE_TX)
          ]


-- | Sample format
data BladeRFFormat = FORMAT_SC16_Q11
                   | FORMAT_SC16_Q11_META
                   deriving (Eq)

instance Enum BladeRFFormat where
  fromEnum = fromJust . flip lookup formats
  toEnum   = fromJust . flip lookup (map swap formats)

formats = [ (FORMAT_SC16_Q11, c'BLADERF_FORMAT_SC16_Q11)
          , (FORMAT_SC16_Q11_META, c'BLADERF_FORMAT_SC16_Q11_META)
          ]


-- | LNA Gain Type??
data BladeRFLNAGain = LNA_GAIN_UNKNOWN
                    | LNA_GAIN_BYPASS
                    | LNA_GAIN_MID
                    | LNA_GAIN_MAX
                    deriving (Eq)

instance Enum BladeRFLNAGain where
  fromEnum = fromJust . flip lookup lgains
  toEnum   = fromJust . flip lookup (map swap lgains)

lgains = [ (LNA_GAIN_UNKNOWN, c'BLADERF_LNA_GAIN_UNKNOWN)
         , (LNA_GAIN_BYPASS, c'BLADERF_LNA_GAIN_BYPASS)
         , (LNA_GAIN_MID, c'BLADERF_LNA_GAIN_MID)
         , (LNA_GAIN_MAX, c'BLADERF_LNA_GAIN_MAX)
         ]

--
-- | Device control and configuration
--
-- This section provides functions pertaining to accessing, controlling, and
-- configuring various device options and parameters.
data BladeRFVGAGainBounds = RXVGA1_GAIN_MIN -- ^ Minimum RXVGA1 gain, in dB
                          | RXVGA1_GAIN_MAX -- ^ Maximum RXVGA1 gain, in dB
                          | RXVGA2_GAIN_MIN -- ^ Minimum RXVGA2 gain, in dB
                          | RXVGA2_GAIN_MAX -- ^ Maximum RXVGA2 gain, in dB
                          | TXVGA1_GAIN_MIN -- ^ Minimum TXVGA1 gain, in dB
                          | TXVGA1_GAIN_MAX -- ^ Maximum TXVGA1 gain, in dB
                          | TXVGA2_GAIN_MIN -- ^ Minimum TXVGA2 gain, in dB
                          | TXVGA2_GAIN_MAX -- ^ Maximum TXVGA2 gain, in dB
                          deriving (Eq)

instance Enum BladeRFVGAGainBounds where
  fromEnum = fromJust . flip lookup vgains
  toEnum   = fromJust . flip lookup (map swap vgains)

vgains = [ (RXVGA1_GAIN_MIN, c'BLADERF_RXVGA1_GAIN_MIN)
         , (RXVGA1_GAIN_MAX, c'BLADERF_RXVGA1_GAIN_MAX)
         , (RXVGA2_GAIN_MIN, c'BLADERF_RXVGA2_GAIN_MIN)
         , (RXVGA2_GAIN_MAX, c'BLADERF_RXVGA2_GAIN_MAX)
         , (TXVGA1_GAIN_MIN, c'BLADERF_TXVGA1_GAIN_MIN)
         , (TXVGA1_GAIN_MAX, c'BLADERF_TXVGA1_GAIN_MAX)
         , (TXVGA2_GAIN_MIN, c'BLADERF_TXVGA2_GAIN_MIN)
         , (TXVGA2_GAIN_MAX, c'BLADERF_TXVGA2_GAIN_MAX)
         ]
