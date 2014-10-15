!!!---------------------------------------------------------------
!!! project : maxent
!!! program : context  module
!!! source  : maxent_context.f90
!!! type    : module
!!! author  : yilin wang (email: qhwyl2006@126.com)
!!! history : 05/29/2013 by yilin wang
!!!           10/13/2014 by yilin wang
!!! purpose : define the global variables for maxent
!!! status  : unstable
!!! comment :
!!!---------------------------------------------------------------

  module databins
     use constants, only : dp

     implicit none

! data generated by Monte Carlo sampling, average of bins
! rotated into diagonal representation of covariance matrix 
     real(dp), public, save, allocatable :: rgrn(:)

! rotated kernel
     real(dp), public, save, allocatable :: rkern(:,:) 

! eigen-value of covariance matrix of data bins
     real(dp), public, save, allocatable :: eigcov(:)

! frequency mesh
     real(dp), public, save, allocatable :: fmesh(:)  

! time mesh
     real(dp), public, save, allocatable :: tmesh(:)

! alpha mesh
     real(dp), public, save, allocatable :: amesh(:)

! default model
     real(dp), public, save, allocatable :: aw_model(:)

! spectrum for each alpha value
     real(dp), public, save, allocatable :: aw_alpha(:,:)

! weight for each alpha 
     real(dp), public, save, allocatable :: weight(:)

! alpha * entropy for each alpha
     real(dp), public, save, allocatable :: ent(:)

! chisquare for each alpha
     real(dp), public, save, allocatable :: chi2(:)

! Q value for each alpha
     real(dp), public, save, allocatable :: qval(:)

  end module databins

  module singular
     use constants, only : dp

     implicit none

! the dimension of the singular space
     integer, public, save :: ns

! the left vectors of svd
     real(dp), public, save, allocatable :: umat(:,:)

! the right vectors of svd
     real(dp), public, save, allocatable :: vmatt(:,:)

! the singular values of svd
     real(dp), public, save, allocatable :: sigvec(:)

! m matrix $M = \Sigma * vmatt * W * vmat * Sigma^T$
     real(dp), public, save, allocatable :: mmat(:,:)


  end module singular

  module context
     use constants, only : zero 
     use control  ! ALL
     use databins ! ALL
     use singular ! ALL
 
     implicit none

     integer, private :: istat

! declaration of module procedures
     public :: maxent_allocate_memory_databins
     public :: maxent_allocate_memory_singular
     public :: maxent_deallocate_memory_databins
     public :: maxent_deallocate_memory_singular

  contains

  subroutine maxent_allocate_memory_databins()
     implicit none

! allocate memory      
     allocate(rgrn(ntime),         stat=istat) 
     allocate(rkern(ntime,nw),     stat=istat)
     allocate(eigcov(ntime),       stat=istat)
     allocate(fmesh(nw),           stat=istat)
     allocate(tmesh(ntime),        stat=istat)
     allocate(amesh(nalpha),       stat=istat)
     allocate(aw_model(nw),        stat=istat)
     allocate(aw_alpha(nw,nalpha), stat=istat)
     allocate(weight(nalpha),      stat=istat)
     allocate(ent(nalpha),         stat=istat)
     allocate(chi2(nalpha),        stat=istat)
     allocate(qval(nalpha),        stat=istat)

! process allocate error
     if ( istat /= 0 ) then
         call s_print_error("maxent_allocate_memory_databins", "can't allocate enough memory")
     endif 

! initialize these variables
     rgrn = zero
     rkern = zero
     eigcov = zero
     fmesh = zero
     tmesh = zero
     amesh = zero
     aw_model = zero
     aw_alpha = zero
     weight = zero
     ent = zero
     chi2 = zero
     qval = zero

     return
  end subroutine maxent_allocate_memory_databins

  subroutine maxent_allocate_memory_singular()

     implicit none

! allocate memory          
     allocate(umat(nw, ns),      stat=istat)
     allocate(vmatt(ns, ntime),  stat=istat)
     allocate(sigvec(ns),        stat=istat)
     allocate(mmat(ns, ns),      stat=istat)

! process allocate error
     if ( istat /= 0 ) then
         call s_print_error("maxent_allocate_memory_singular", "can't allocate enough memory")
     endif 

! initialize them
     umat = zero
     vmatt = zero
     sigvec = zero
     mmat = zero

     return
  end subroutine maxent_allocate_memory_singular

  subroutine maxent_deallocate_memory_databins()
     implicit none

     if( allocated(rgrn)     ) deallocate(rgrn)
     if( allocated(rkern)    ) deallocate(rkern)
     if( allocated(eigcov)   ) deallocate(eigcov)
     if( allocated(fmesh)    ) deallocate(fmesh)
     if( allocated(tmesh)    ) deallocate(tmesh)
     if( allocated(amesh)    ) deallocate(amesh)
     if( allocated(aw_model) ) deallocate(aw_model)
     if( allocated(aw_alpha) ) deallocate(aw_alpha)
     if( allocated(weight)   ) deallocate(weight)
     if( allocated(ent)      ) deallocate(ent)
     if( allocated(chi2)     ) deallocate(chi2)
     if( allocated(qval)     ) deallocate(qval)

     return
  end subroutine maxent_deallocate_memory_databins

  subroutine maxent_deallocate_memory_singular()
     implicit none
 
     if( allocated(umat)  ) deallocate(umat) 
     if( allocated(vmatt) ) deallocate(vmatt) 
     if( allocated(sigvec)) deallocate(sigvec) 
     if( allocated(mmat)  ) deallocate(mmat) 

     return
  end subroutine maxent_deallocate_memory_singular

  end module context
