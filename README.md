# 5G NR Transceiver implementation - PHY Layer
This matlab program will implement the below: \
1.Generate a transport block and append CRC \
2.Segment the TB and append CRC to each segment \
3.LDPC encode all segments along with BPSK modulation and add some noise\
4.On the receiver side, demodulate BPSK noisy modulated signal \
5.Performs LDPC decoding of all segments \
6.Validation of all segments for CRC and TB CRC after concatenation \
7.Validates the transmotted and received TBs match

This program is interactive matlab implementation for the above.  

