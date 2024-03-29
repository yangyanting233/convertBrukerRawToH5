function [ data ] = convertFrameToCKData( data, Acqp, varargin )
% function ckdata = convertFrameToCKData(frame, Acqp, Method, ['specified_NRs', NRarray], ['useMethod', useMethod])
% Attention: Currently works with RARE, FLASH, MSME, FISP only.
%
% Input:
%   frame: frame data as generated by convertRawToFrame 
%
%   Acqp (struct): An acqp struct as generated by the function readBrukerParamFile('path/acqp')
%
% Optional Input:
%   Method: A method struct generated by the function readBrukerParamFile('path/method')
%           This input is only required if useMethod is true
%
%   'specified_NRs', NRarray: A list of repetitions to be converted, NR starting with 1 
%                             'specified_NRs',[2 5 7] -> only NR 2, 5 and 7 are converted
%
%   'useMethod', useMethod: Used to specify whether the method parameters should be used,
%                           e.g. set useMethod to false when required parameters in the
%                           method file are missing. Default is true.
%
% Output:
%   ckdata: 7D Cartesian k-space matrix, with dimensions 
%           (dim1, dim2, dim3, dim4, NumberOfChannels, NumberOfObjects, NumberOfRepetitions)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright (c) 2013-2019
% Bruker BioSpin MRI GmbH
% D-76275 Ettlingen, Germany
%
% All Rights Reserved
%
% $Id$
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %% Define default-value if necesseary:
    [varargin, specified_NRs]=bruker_addParamValue(varargin, 'specified_NRs', '@(x) isnumeric(x)', []);
    [varargin, useMethod] =bruker_addParamValue(varargin, 'useMethod', '@(x) islogical(x)', true);
    
    if length(varargin) == 1
        Method=varargin{1};
    elseif isempty(varargin) 
        Method=struct();
    else
        warning('MATLAB:bruker_warning', 'Check your input arguments of function readBrukerRaw')
    end
    
    
    % Check for missing variables in structs:
    cellstruct{1}=Acqp;
    if useMethod
        cellstruct{2}=Method;
        all_here = bruker_requires(cellstruct, {'Acqp','NI','NR','ACQ_dim'}, {'Method', 'PVM_Matrix', 'PVM_EncSteps1'});
    else
        all_here = bruker_requires(cellstruct, {'Acqp','NI','NR','ACQ_dim'});
    end
    clear cellstruct;
    if ~all_here
        error('Some parameters are missing. You can try: ''useMethod'', false');
    end
    
    %Init:
    if bruker_getAcqPvVersion(Acqp, 'is360')
        AQ_mod='qdig';
    else
        if ~isfield(Acqp, 'AQ_mod')
            error('AQ_mod parameter is missing.');
        end
        AQ_mod=Acqp.AQ_mod;
    end
    NI=Acqp.NI;
    if ~isempty(specified_NRs)
        NR=length(specified_NRs);
    else
        NR=Acqp.NR; 
    end
    ACQ_size=bruker_getAcqSizes(Acqp);
    ACQ_dim=Acqp.ACQ_dim;
    
    if useMethod % don't read when method=disabled
        if ACQ_dim==3
            if isfield(Method, 'PVM_EncSteps2')
                PVM_EncSteps2=Method.PVM_EncSteps2;
            else
                error('Method.PVM_EncStep2 is missing!');
            end
        end       
        PVM_Matrix=Method.PVM_Matrix;
        PVM_EncSteps1=Method.PVM_EncSteps1;
    end
    
    % read precision:
    temp=whos('data');
    precision=temp.class;
    clear temp;
    % Convert precision-string to boolean-variable:
    if(strcmpi(precision, 'single'))
        memsave=true;
    else
        memsave=false;
    end
    clear precision;

    %% Calculate additional Parameters  
    
     % decide if RawFile is complex or real:
    switch AQ_mod
        case ('qf')
            isComplex=false;
        case ('qseq')
            isComplex=true;
        case ('qsim')
            isComplex=true;
        case ('qdig')
            isComplex=true;
        otherwise
            error('The value of parameter AQ_mod is not supported');
    end
    
    
    numSelectedReceivers=size(data,3);
    
    % Convert if complex: to blockSize of a complex Matrix and change
    % ACQ_size(1)
    if isComplex
        scanSize(1)=ACQ_size(1)/2;
    else
        scanSize(1)=ACQ_size(1);
    end

   %% Resort Matrix
   if useMethod
       % use also method-parameters
       if ACQ_dim>1
           
           frameData=data;

           % MGE with alternating k-space readout: Reverse every second
           % scan. As in this case, the method ensures that the number of 
           % echos is even the reversal can happen in one step, also for 
           % multi-slice mode.
           if isfield(Method, 'EchoAcqMode') && strcmpi(Method.EchoAcqMode, 'allEchoes') == true
               frameData(:,:,:,2:2:end)=flipdim(data(:,:,:,2:2:end),1);
           end

           % Reshape:
            if ACQ_dim==2
                frameData=reshape(frameData,[ scanSize ACQ_size(2) 1 1 numSelectedReceivers NI NR]);
                if memsave
                    data=zeros([ scanSize ACQ_size(2) 1 1 numSelectedReceivers NI NR],'single' );
                else
                    data=zeros([ scanSize ACQ_size(2) 1 1 numSelectedReceivers NI NR]);
                end
                data(1:scanSize,PVM_EncSteps1+fix(Method.PVM_AntiAlias(2)*PVM_Matrix(2)/2)+1,1,1,:,:,:)=frameData; % kspace: from (-n/2) to (+n/2-1) -> in matlab: 1 to n
                
                
            elseif ACQ_dim==3
                frameData=reshape(frameData,[ scanSize ACQ_size(2) ACQ_size(3) 1 numSelectedReceivers NI NR]);
                if memsave
                    data=zeros([ PVM_Matrix(1) PVM_Matrix(2) PVM_Matrix(3) 1 numSelectedReceivers NI NR],'single');
                else
                    data=zeros([ PVM_Matrix(1) PVM_Matrix(2) PVM_Matrix(3) 1 numSelectedReceivers NI NR]);
                end
                data(1:scanSize,PVM_EncSteps1+fix(Method.PVM_AntiAlias(2)*PVM_Matrix(2)/2)+1,PVM_EncSteps2+fix(Method.PVM_AntiAlias(3)*PVM_Matrix(3)/2)+1,1,:,:,:)=frameData;
            else
                error('Unknown ACQ_dim with useMethod');
            end
            clear frameData;

        else
            % dim=1:
            data=reshape(data,scanSize,numSelectedReceivers,1,1,NI,NR);
        end
       
   else % <- useMethod=false
       % use acqp-parameters instead:
       if ACQ_dim>1

            % Reshape:
            if ACQ_dim==2
                data=reshape(data,[ scanSize ACQ_size(2) 1 1 numSelectedReceivers NI NR]);
                
            elseif ACQ_dim==3
                data=reshape(data,[ scanSize ACQ_size(2) ACQ_size(3) 1 numSelectedReceivers NI NR]);
            elseif ACQ_dim==4
                data=reshape(data,[ scanSize ACQ_size(2) ACQ_size(3) ACQ_size(4) numSelectedReceivers NI NR]);               
            else
                error('Unknown ACQ_dim.');
            end

        else
            % dim=1:
            data=reshape(data,scanSize,1,1,numSelectedReceivers,NI,NR);
       end
   end

end

