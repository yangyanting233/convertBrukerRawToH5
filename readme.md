# convertBrukerRawToH5

## Example

Step 0: Run `step0_raw_to_mat.m` to convert raw fid to mat file.

Step 1: Run the following command to convert mat file to h5 file.

```bash
python step1_mat_to_h5.py --in_fname 20220801_110450_AntiVCAM1_CTL_ID001_F_18mon_TP0_1_1.mat --out_fname 20220801_110450_AntiVCAM1_CTL_ID001_F_18mon_TP0_1_1.h5
```

Step 2: Follow the code in `step2_kspace_to_image.ipynb` to convert kspace data into image.

Use MATLAB [parfor](https://www.mathworks.com/help/matlab/ref/parfor.html), Python [multiprocessing](https://docs.python.org/3/library/multiprocessing.html) package or GNU [parallel](https://www.gnu.org/software/parallel/) for parallel execution.
