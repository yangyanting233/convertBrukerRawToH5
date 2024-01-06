function exitcode = recon(pdataPath,out_fname)
    kdataObj = CKDataObject(pdataPath);
    outObj = kdataObj.reco({'zero_filling'});
    kspace = single(outObj.data);
    save(out_fname,'kspace','-v7.3','-nocompression');
    exitcode = 0;
end