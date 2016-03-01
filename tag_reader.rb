require 'libusb'
require 'pathname'

class TagReader
  # TODO: no depend on nfcpy
  NFCPY_PREFIX = "#{Pathname.pwd}/nfcpy/0.9"

  # target nfc reader is only '054c:02e1 Sony Corp. FeliCa S330 [PaSoRi]'
  VENDER = '054c'.to_i(16)
  PRODUCT = '02e1'.to_i(16)
  TAG_FOR_VIRTUAL = '048d607aba2b80'

  def initialize
    usb = LIBUSB::Context.new
    unless usb.devices(idVender: VENDER, idProduct: PRODUCT).empty?
      @reader_method = '_read_by_real_reader'
    else
      @reader_method = '_read_by_virtual_reader'
    end
    self
  end

  def read
    eval(@reader_method)
  end

  # use when target nfc reader connect
  def _read_by_real_reader
    # TODO: no depend on nfcpy
    cmd_out = `python #{NFCPY_PREFIX}/examples/tagtool.py show 2>/dev/null`
    raise if cmd_out.empty?
    cmd_out.match(/IDm?=([\da-fA-F]*)/)[1]
  end

  # use when no nfc reader connect
  def _read_by_virtual_reader
    TAG_FOR_VIRTUAL
  end
end
