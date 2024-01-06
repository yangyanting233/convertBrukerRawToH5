import argparse

import h5py
import numpy as np

def main(in_fname, out_fname):
    with h5py.File(in_fname) as f:
        kspace = f['kspace'][:]
    kspace = kspace['real'] + 1j*kspace['imag']
    kspace = kspace.astype(np.complex64)
    kspace = np.transpose(kspace, list(reversed(range(kspace.ndim))))
    with h5py.File(out_fname, 'w') as f:
        f['kspace'] = kspace


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--in_fname', required=True)
    parser.add_argument('--out_fname', required=True)

    args = parser.parse_args()

    main(args.in_fname, args.out_fname)