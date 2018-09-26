#include "../interface/PulseChiSqSNNLS.h"
#include <math.h>
#include <iostream>
#include <thrust/swap.h>


// __global__ void GpuDoFit(PulseChiSqSNNLS *pulse, DoFitArgs *parameters, bool *status){
  //   int i = blockIdx.x*blockDim.x + threadIdx.x;
  //   auto args = parameters[i];
  //   status[i] = pulse[i].DoFit(args.samples, args.samplecor, args.pederr, args.bxs, args.fullpulse, args.fullpulsecov);
  // }


__host__ __device__ bool PulseChiSqSNNLS::DoFit(const SampleVector &samples, const SampleMatrix &samplecor, 
                                       double pederr, const BXVector &bxs, const FullSampleVector &fullpulse,
                                       const FullSampleMatrix &fullpulsecov) {
  
  const unsigned int nsample = SampleVector::RowsAtCompileTime;
  const unsigned int npulse = bxs.rows();
  
  _sampvec = samples;
  _bxs = bxs;
  
  _pulsemat = SamplePulseMatrix::Zero(nsample,npulse);
  _ampvec = PulseVector::Zero(npulse);
  _errvec = PulseVector::Zero(npulse);  
  _nP = 0;
  _chisq = 0.;
  
  //initialize pulse template matrix
  for (unsigned int ipulse=0; ipulse<npulse; ++ipulse) {
    int bx = _bxs.coeff(ipulse);
    int firstsamplet = std::max(0,bx + 3);
    int offset = 7-3-bx;
    
    const unsigned int nsamplepulse = nsample-firstsamplet;
    _pulsemat.col(ipulse).segment(firstsamplet,nsamplepulse) = fullpulse.segment(firstsamplet+offset,nsamplepulse);
  }
  
  //do the actual fit
  bool status = Minimize(samplecor,pederr,fullpulsecov);
  _ampvecmin = _ampvec;
  
//   std::cout << " _sampvec = " << _sampvec << std::endl;
//   std::cout << " bxs = " << bxs << std::endl;
//   std::cout << " fullpulse = " << fullpulse << std::endl;
//   std::cout << " _ampvecmin = " << _ampvecmin << std::endl;
  
  _bxsmin = _bxs;
  
  if (!status) return status;
  
//   std::cout << " _computeErrors = " << _computeErrors << std::endl;
  
  if(!_computeErrors) return status;
  
  //compute MINOS-like uncertainties for in-time amplitude
  bool foundintime = false;
  unsigned int ipulseintime = 0;
//   std::cout << " npulse = " << npulse << std::endl;
  for (unsigned int ipulse=0; ipulse<npulse; ++ipulse) {
//     std::cout << " _bxs.coeff( " << ipulse << "::" << npulse << " ) = " << _bxs.coeff(ipulse) << std::endl;
    if (_bxs.coeff(ipulse)==0) {
      ipulseintime = ipulse;
      foundintime = true;
      break;
    }
  }
//   std::cout << " foundintime = " << foundintime << std::endl;
  if (!foundintime) return status;
  
  
  
  const unsigned int ipulseintimemin = ipulseintime;
  
  double approxerr = ComputeApproxUncertainty(ipulseintime);
  double chisq0 = _chisq;
  double x0 = _ampvecmin[ipulseintime];  
  
  //move in time pulse first to active set if necessary
  if (ipulseintime<_nP) {
    _pulsemat.col(_nP-1).swap(_pulsemat.col(ipulseintime));
    thrust::swap(_ampvec.coeffRef(_nP-1),_ampvec.coeffRef(ipulseintime));
    thrust::swap(_bxs.coeffRef(_nP-1),_bxs.coeffRef(ipulseintime));
    ipulseintime = _nP - 1;
    --_nP;    
  }
  
  
  
  SampleVector pulseintime = _pulsemat.col(ipulseintime);
  _pulsemat.col(ipulseintime).setZero();
  
  //two point interpolation for upper uncertainty when amplitude is away from boundary
  double xplus100 = x0 + approxerr;
  _ampvec.coeffRef(ipulseintime) = xplus100;
  _sampvec = samples - _ampvec.coeff(ipulseintime)*pulseintime;  

//   std::cout << " here 1 " << std::endl;
  status &= Minimize(samplecor,pederr,fullpulsecov);
  if (!status) return status;
  double chisqplus100 = ComputeChiSq();
  
//   std::cout << " here 2 " << std::endl;
  
  
  double sigmaplus = std::abs(xplus100-x0)/sqrt(chisqplus100-chisq0);
  
  //if amplitude is sufficiently far from the boundary, compute also the lower uncertainty and average them
  if ( (x0/sigmaplus) > 0.5 ) {
    for (unsigned int ipulse=0; ipulse<npulse; ++ipulse) {
      if (_bxs.coeff(ipulse)==0) {
        ipulseintime = ipulse;
        break;
      }
    }    
    double xminus100 = std::max(0.,x0-approxerr);
    _ampvec.coeffRef(ipulseintime) = xminus100;
    _sampvec = samples - _ampvec.coeff(ipulseintime)*pulseintime;
    status &= Minimize(samplecor,pederr,fullpulsecov);
    if (!status) return status;
    double chisqminus100 = ComputeChiSq();
    
    double sigmaminus = std::abs(xminus100-x0)/sqrt(chisqminus100-chisq0);
    _errvec[ipulseintimemin] = 0.5*(sigmaplus + sigmaminus);
    
  }
  else {
    _errvec[ipulseintimemin] = sigmaplus;
  }
  
  _chisq = chisq0;  
  
  return status;
  
}

__host__ __device__ bool PulseChiSqSNNLS::Minimize(const SampleMatrix &samplecor, double pederr, 
                                          const FullSampleMatrix &fullpulsecov) {
  
  
  const int maxiter = 50;
  for (int iter=0; iter<maxiter; ++iter){
    if(!(updateCov(samplecor,pederr,fullpulsecov) &&  NNLS()))
      return false;    
    double chisqnow = ComputeChiSq();
    double deltachisq = chisqnow-_chisq; 
    _chisq = chisqnow;
    if (std::abs(deltachisq)<1e-3)
      break;
  }    
  return true;  
}

__host__ __device__ bool PulseChiSqSNNLS::updateCov(const SampleMatrix &samplecor, double pederr,
                                           const FullSampleMatrix &fullpulsecov) {
  const unsigned int nsample = SampleVector::RowsAtCompileTime;
  const unsigned int npulse = _bxs.rows();
  
  _invcov.triangularView<Eigen::Lower>() = (pederr*pederr)*samplecor;
  
  for (unsigned int ipulse=0; ipulse<npulse; ++ipulse) {
    if (_ampvec.coeff(ipulse)==0.) continue;
    int bx = _bxs.coeff(ipulse);
    int firstsamplet = std::max(0,bx + 3);
    int offset = 7-3-bx;
    
    double ampsq = _ampvec.coeff(ipulse)*_ampvec.coeff(ipulse);
    
    const unsigned int nsamplepulse = nsample-firstsamplet;    
    _invcov.block(firstsamplet,firstsamplet,nsamplepulse,nsamplepulse).triangularView<Eigen::Lower>() +=
      ampsq*fullpulsecov.block(firstsamplet+offset,firstsamplet+offset,nsamplepulse,nsamplepulse);    
  }
  
  _covdecomp.compute(_invcov);
    
  return true;  
}

__host__ __device__ double PulseChiSqSNNLS::ComputeChiSq() {
  
  //   SampleVector resvec = _pulsemat*_ampvec - _sampvec;
  //   return resvec.transpose()*_covdecomp.solve(resvec);
  
  // TODO: port Eigen::LLT solve to gpu
  return _covdecomp.matrixL().solve(_pulsemat*_ampvec - _sampvec).squaredNorm();
  // return 1.0;
}

__host__ __device__ double PulseChiSqSNNLS::ComputeApproxUncertainty(unsigned int ipulse) {
  //compute approximate uncertainties
  //(using 1/second derivative since full Hessian is not meaningful in
  //presence of positive amplitude boundaries.)
   

  // TODO: port Eigen::LLT solve to gpu
  return 1./_covdecomp.matrixL().solve(_pulsemat.col(ipulse)).norm();
  // return 1.;
  
}

__host__ __device__ bool PulseChiSqSNNLS::NNLS() {
  
  //Fast NNLS (fnnls) algorithm as per http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.157.9203&rep=rep1&type=pdf
  
  const unsigned int npulse = _bxs.rows();
  // TODO: Port EigenLLT to gpu
  SamplePulseMatrix invcovp = _covdecomp.matrixL().solve(_pulsemat);
  // SamplePulseMatrix invcovp;

  PulseMatrix aTamat(npulse,npulse);
  aTamat.triangularView<Eigen::Lower>() = invcovp.transpose()*invcovp;
  aTamat = aTamat.selfadjointView<Eigen::Lower>();

  // TODO: Port EigenLLT to gpu
  PulseVector aTbvec = invcovp.transpose()*_covdecomp.matrixL().solve(_sampvec);  
  // PulseVector aTbvec;
  
  PulseVector wvec(npulse);
  
  
  for (int iter=0; iter<1000; iter++) {    
    //can only perform this step if solution is guaranteed viable
    if (iter>0 || _nP==0) {
      if ( _nP==npulse ) break;                  
      
      const unsigned int nActive = npulse - _nP;
      
      wvec.tail(nActive) = aTbvec.tail(nActive) - (aTamat.selfadjointView<Eigen::Lower>()*_ampvec).tail(nActive);       
      
      Index idxwmax;
      double wmax = wvec.tail(nActive).maxCoeff(&idxwmax);
      
      //convergence
      if (wmax<1e-11) break;
      
      //unconstrain parameter
      Index idxp = _nP + idxwmax;
      //printf("adding index %i, orig index %i\n",int(idxp),int(_bxs.coeff(idxp)));
      aTamat.col(_nP).swap(aTamat.col(idxp));
      aTamat.row(_nP).swap(aTamat.row(idxp));
      _pulsemat.col(_nP).swap(_pulsemat.col(idxp));
      thrust::swap(aTbvec.coeffRef(_nP),aTbvec.coeffRef(idxp));
      thrust::swap(_ampvec.coeffRef(_nP),_ampvec.coeffRef(idxp));
      thrust::swap(_bxs.coeffRef(_nP),_bxs.coeffRef(idxp));
      ++_nP;
    }
    
    
    while (_nP > 0) {
      //printf("iter in, idxsP = %i\n",int(_idxsP.size()));
      
//       std::cout << " >>  iter = " << iter << std::endl;
      
      // TODO: port EigenLDLT solve to gpu
      PulseVector ampvecpermtest = _ampvec;
      
      //solve for unconstrained parameters      
      
      // TODO: port Eigen::LDLT solve to gpu
      ampvecpermtest.head(_nP) = aTamat.topLeftCorner(_nP,_nP).ldlt().solve(aTbvec.head(_nP));     
      // ampvecpermtest.head(_nP) = aTamat.topLeftCorner(_nP,_nP);     
     
      //check solution
      if (ampvecpermtest.head(_nP).minCoeff()>0.) {
        _ampvec.head(_nP) = ampvecpermtest.head(_nP);
        break;
      }      
      
      //update parameter vector
      Index minratioidx=0;
      
      double minratio = std::numeric_limits<double>::max();
      for (unsigned int ipulse=0; ipulse<_nP; ++ipulse) {
        if (ampvecpermtest.coeff(ipulse)<=0.) {
          double ratio = _ampvec.coeff(ipulse)/(_ampvec.coeff(ipulse)-ampvecpermtest.coeff(ipulse));
          if (ratio<minratio) {
            minratio = ratio;
            minratioidx = ipulse;
          }
        }
      }
      
      _ampvec.head(_nP) += minratio*(ampvecpermtest.head(_nP) - _ampvec.head(_nP));
      
      //avoid numerical problems with later ==0. check
      _ampvec.coeffRef(minratioidx) = 0.;
      
      //printf("removing index %i, orig idx %i\n",int(minratioidx),int(_bxs.coeff(minratioidx)));
      aTamat.col(_nP-1).swap(aTamat.col(minratioidx));
      aTamat.row(_nP-1).swap(aTamat.row(minratioidx));
      _pulsemat.col(_nP-1).swap(_pulsemat.col(minratioidx));
      thrust::swap(aTbvec.coeffRef(_nP-1),aTbvec.coeffRef(minratioidx));
      thrust::swap(_ampvec.coeffRef(_nP-1),_ampvec.coeffRef(minratioidx));
      thrust::swap(_bxs.coeffRef(_nP-1),_bxs.coeffRef(minratioidx));
      --_nP;
      
    }
  }
  
  return true;
  
  
}

__host__ __device__ PulseChiSqSNNLS::PulseChiSqSNNLS() : _chisq(0.), _computeErrors(true) {}

__global__ void kernel_multifit(DoFitArgs *vargs, Output *vresults, unsigned int n) {
    // thread idx
    int i = blockIdx.x*blockDim.x + threadIdx.x;
    if (i>=n) return;

    PulseChiSqSNNLS pulse;
    pulse.disableErrorCalculation();
    auto args = vargs[i];

    // perform the regression
    auto status = pulse.DoFit(args.samples, args.samplecor, args.pederr, args.bxs, args.fullpulse, args.fullpulsecov);

    unsigned int ip_in_time = 0;
    for (unsigned int ip=0; ip<pulse.BXs().rows(); ++ip) {
        if (ip < pulse.BXs().coeff(ip) == 0) {
            ip_in_time = ip;
            break;
        }
    }

    // assing the result
    BXVector BXs_results = pulse.BXs();
    PulseVector X_results = pulse.X();
    
    vresults[i] = Output{pulse.ChiSq(), status ? pulse.X()[ip_in_time] : 0.0, status, BXs_results, X_results};

    // assing the result
    //vresults[i] = DoFitResults{pulse.ChiSq(), pulse.BXs(), pulse.X(), (bool) status}; 
}
