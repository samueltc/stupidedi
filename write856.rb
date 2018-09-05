require "./lib/stupidedi"

config = Stupidedi::Config.contrib(Stupidedi::Config.hipaa(Stupidedi::Config.default))

b = Stupidedi::Builder::BuilderDsl.build(config)

po_number = "1D111888"
receiver_code = "10401111T"
sender_code = "010020001"
vendor_code = "AA"
interchange_sender_id = "#{sender_code}-#{vendor_code}"
isa_control_number = "000001"
gs_control_number = "000002"
st_control_number = "000003"

shipment_identification = "ID1234567"

b.ISA "00", nil, "00", nil,
      "ZZ", interchange_sender_id,
      "01", receiver_code,
      Time.now.utc, Time.now.utc, "U", "00400", isa_control_number, "0", "T", "#"

b.GS "SH", sender_code, receiver_code, Time.now.utc, Time.now.utc, gs_control_number, "X", "004010"

b.ST "856", st_control_number
  b.BSN "00", shipment_identification, Time.now.utc, Time.now.utc
  ## DTM
  # 011 = Shipped
  # 017 = ETA
  b.DTM "011", Time.now.utc, Time.now.utc

b.HL "1", nil, "S", "1"
  b.MEA "PD", "G", "3401", "LB"
  b.MEA "PD", "N", "3400", "LB"
  b.TD1 "PLT", "3"
  b.TD5 "B", "25", "SAMEDAYRIGHT-O-WAY", "L", nil
  b.TD3 "TL", shipment_identification
  b.REF "BM", shipment_identification
  b.N1 "SU", "PARTS CANADA", "92", interchange_sender_id
  b.N3 "65 MAIN ST."
  b.N4 "LAVAL", "QC", "H0H 0H0", "CAN"

b.HL "2", "1", "O", "1"
  b.PRF po_number
  b.REF "MH", po_number

  b.N1 "ST", "RICHMOND PDC PARTS DIST CENTRE", "92", receiver_code
  b.N3 "30 PROGRESS AVE"
  b.N4 "SCARBOROUGH", "ON", "M1H2X5", "CAN"


#b.HL "3", "2", "I", "0"
#  b.LIN "1", "BP", "C000202"
#  b.SN1 nil, "40", "PC"

b.machine.zipper.tap do |z|
  # The :component, and :repetition parameters can also be specified as elements
  # of the ISA segment, at `b.ISA(...)` above. When generating a document from
  # scratch, :segment and :element must be specified -- if you've parsed the doc
  # from a file, these params will default to whatever was used in the file, or
  # you can override them here.
  separators =
    Stupidedi::Reader::Separators.build :segment    => "$\n",
                                        :element    => "*",
                                        :component  => ":",
                                        :repetition => "^"

  # You can also serialize any subtree within the document (e.g., everything inside
  # some ST..SE transaction set, or a single loop. Here, z.root is the entire tree.
  w = Stupidedi::Writer::Default.new(z.root, separators)
  print w.write()
end
