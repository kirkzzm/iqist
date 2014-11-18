!!!-----------------------------------------------------------------------
!!! project : hibiscus/stoch
!!! program : sac_warmming
!!!           sac_sampling
!!!           sac_make_mov1
!!!           sac_make_mov2
!!!           sac_make_swap
!!! source  : sac_update.f90
!!! type    : subroutines
!!! author  : li huang (email:huangli712@yahoo.com.cn)
!!! history : 01/09/2011 by li huang
!!!           01/11/2011 by li huang
!!!           11/18/2014 by li huang
!!! purpose : to provide some basic infrastructures (elementary updating
!!!           subroutines) for stochastic analytic continuation code
!!! status  : unstable
!!! comment :
!!!-----------------------------------------------------------------------

!!>>> sac_warmming: warm up the configurations
  subroutine sac_warmming()
     use constants, only : zero

     use control, only : nwarm
     use context, only : move_accept, move_reject, move_tcount
     use context, only : swap_accept, swap_reject, swap_tcount

     implicit none

! local variables
! loop index
     integer :: i

     do i=1,nwarm
         call sac_sampling()
     enddo ! over i={1,nwarm} loop

! reset the statistics
     move_accept = zero
     move_reject = zero
     move_tcount = zero

     swap_accept = zero
     swap_reject = zero
     swap_tcount = zero

     return
  end subroutine sac_warmming

!!>>> sac_sampling: selector, choose update scheme randomly
  subroutine sac_sampling()
     use constants, only : dp
     use spring, only : spring_sfmt_stream

     use control, only : nalph

     implicit none

! local variables
! loop index
     integer :: i

! perform local update action
     if ( spring_sfmt_stream() < 0.90_dp .or. nalph == 1 ) then
         if ( spring_sfmt_stream() > 0.50_dp ) then
             do i=1,nalph
                 call sac_make_mov1(i)
             enddo ! over i={1,nalph} loop
         else
             do i=1,nalph
                 call sac_make_mov2(i)
             enddo ! over i={1,nalph} loop
         endif ! back if ( spring_sfmt_stream() > 0.50_dp ) block
! perform global update action
! note: if nalph == 1, the global update is forbidden
     else
         if ( spring_sfmt_stream() > 0.10_dp ) then
             call sac_make_swap(1)
         else
             call sac_make_swap(2)
         endif ! back if ( spring_sfmt_stream() > 0.10_dp ) block
     endif ! back if ( spring_sfmt_stream() < 0.90_dp .or. nalph == 1 ) block

     return
  end subroutine sac_sampling

!>>> standard update, move the configurations: shift the weight
  subroutine sac_make_mov1(ia)
     use constants
     use control
     use context

     use spring

     implicit none

! external arguments
! current alpha index
     integer, intent(in) :: ia

! local variables
! whether the update action is accepted
     logical  :: pass

! loop index
     integer  :: n

! \lambda_1 and \lambda_2
     integer  :: l1, l2

! integer dummy variables
     integer  :: i1, i2

! real(dp) dummy variables
     real(dp) :: r1, r2
     real(dp) :: r3, r4

! \Delta H_C
     real(dp) :: dhh

! current h_C(\tau)
     real(dp) :: hc(ntime)

! \Delta h_C(\tau)
     real(dp) :: dhc(ntime)

! init h_C and \Delta h_C
     hc  = zero
     dhc = zero

! build initial h_C from input configuration r_{\gamma} and a_{\gamma}
     call sac_make_hamil0( rgamm(ia,:), igamm(ia,:), hc )

! generate two random integers in [1,ngamm] as \lambda1, \lambda2
     do while ( .true. )
         l1 = ceiling( spring_sfmt_stream() * ngamm )
         l2 = ceiling( spring_sfmt_stream() * ngamm )
         if ( l1 /= l2 ) EXIT
     enddo ! over do while loop

! get dummy updated r_{\gamma}
! note: here dhh is used as a dummy variable
     r3 = rgamm(ia,l1); r4 = rgamm(ia,l2)
     do while ( .true. )
         dhh = spring_sfmt_stream() * ( r3 + r4 ) - r3
         r1 = r3 + dhh; r2 = r4 - dhh
         if ( r1 > zero .and. r2 > zero ) EXIT
     enddo ! over do while loop

! get dummy updated a_{\gamma}
     i1 = igamm(ia,l1); i2 = igamm(ia,l2)

! calculate \Delta h_C using equation (41)
     dhc = zero
     do n=1,ntime
         dhc(n) = ( dhh * ( fkern(n,i1) - fkern(n,i2) ) ) / G_dev(n)
     enddo ! over n={1,ntime} loop

! calculate \Delta H_C = H_C'- H_C using equation (42)
     dhh = zero
     do n=1,ntime
         dhh = dhh + dhc(n) * ( two * hc(n) + dhc(n) )
     enddo ! over n={1,ntime} loop
     dhh = dhh * ( tmesh(2) - tmesh(1) )

! judge the possibility of update action
     pass = .false.
     if ( dhh <= zero .or. exp( -alpha(ia) * dhh ) > spring_sfmt_stream() ) then
         pass = .true.
     endif

! if update action is accepted
     if ( pass .eqv. .true. ) then

! update h_C(\tau)
         hc = hc + dhc

! update the configurations
         rgamm(ia,l1) = r1; rgamm(ia,l2) = r2

     endif ! back if ( pass .eqv. .true. ) block

! update the accept/reject statistics
     move_tcount(ia) = move_tcount(ia) + one
     if ( pass .eqv. .true. ) then
         move_accept(ia) = move_accept(ia) + one
     else
         move_reject(ia) = move_reject(ia) + one
     endif ! back if ( pass .eqv. .true. ) block

! recalculate hamiltonian in new configuration
     call sac_make_hamil1( hc, hamil(ia) )

     return
  end subroutine sac_make_mov1

!>>> standard update, move the configurations: shift the coordinates
  subroutine sac_make_mov2(ia)
     use constants
     use control
     use context

     use spring

     implicit none

! external arguments
! current alpha index
     integer, intent(in) :: ia

! local variables
! whether the update action is accepted
     logical  :: pass

! loop index
     integer  :: n

! \lambda_1 and \lambda_2
     integer  :: l1, l2

! integer dummy variables
     integer  :: i1, i2
     integer  :: i3, i4

! real(dp) dummy variables
     real(dp) :: r1, r2

! \Delta H_C
     real(dp) :: dhh

! current h_C(\tau)
     real(dp) :: hc(ntime)

! \Delta h_C(\tau)
     real(dp) :: dhc(ntime)

! init h_C and \Delta h_C
     hc  = zero
     dhc = zero

! build initial h_C from input configuration r_{\gamma} and a_{\gamma}
     call sac_make_hamil0( rgamm(ia,:), igamm(ia,:), hc )

! generate two random integers in [1,ngamm] as \lambda1, \lambda2
     do while ( .true. )
         l1 = ceiling( spring_sfmt_stream() * ngamm )
         l2 = ceiling( spring_sfmt_stream() * ngamm )
         if ( l1 /= l2 ) EXIT
     enddo ! over do while loop

! get dummy updated r_{\gamma}
     r1 = rgamm(ia,l1); r2 = rgamm(ia,l2)

! get dummy updated a_{\gamma}
     i1 = ceiling( spring_sfmt_stream() * ngrid ); i3 = igamm(ia,l1)
     i2 = ceiling( spring_sfmt_stream() * ngrid ); i4 = igamm(ia,l2)

! calculate \Delta h_C using equation (41)
     dhc = zero
     do n=1,ntime
         dhc(n) = ( r1 * ( fkern(n,i1) - fkern(n,i3) ) + r2 * ( fkern(n,i2) - fkern(n,i4) ) ) / G_dev(n)
     enddo ! over n={1,ntime} loop

! calculate \Delta H_C = H_C'- H_C using equation (42)
     dhh = zero
     do n=1,ntime
         dhh = dhh + dhc(n) * ( two * hc(n) + dhc(n) )
     enddo ! over n={1,ntime} loop
     dhh = dhh * ( tmesh(2) - tmesh(1) )

! judge the possibility of update action
     pass = .false.
     if ( dhh <= zero .or. exp( -alpha(ia) * dhh ) > spring_sfmt_stream() ) then
         pass = .true.
     endif

! if update action is accepted
     if ( pass .eqv. .true. ) then

! update h_C(\tau)
         hc = hc + dhc

! update the configurations
         igamm(ia,l1) = i1; igamm(ia,l2) = i2

     endif ! back if ( pass .eqv. .true. ) block

! update the accept statistics
     move_tcount(ia) = move_tcount(ia) + one
     if ( pass .eqv. .true. ) then
         move_accept(ia) = move_accept(ia) + one
     else
         move_reject(ia) = move_reject(ia) + one
     endif ! back if ( pass .eqv. .true. ) block

! recalculate hamiltonian in new configuration
     call sac_make_hamil1( hc, hamil(ia) )

     return
  end subroutine sac_make_mov2

!>>> global update, parallel tempering
  subroutine sac_make_swap(scheme)
     use constants
     use control
     use context

     use spring

     implicit none

! external arguments
! swap scheme
! if scheme == 1, swap alpha with neighbour
! if scheme == 2, swap alpha randomly
     integer, intent(in) :: scheme

! local variables
! whether swap action is accepted
     logical  :: pass

! selected alpha index
     integer  :: i
     integer  :: j

! \delta alpha = \alpha_{i} - \alpha_{j}
     real(dp) :: da

! \delta hamiltonian = H_C_{i} - H_C_{j}
     real(dp) :: dh

! current h_C(\tau)
     real(dp) :: hc(ntime)

! init h_C
     hc = zero

     if ( scheme == 1 ) then

! choose the first alpha index randomly
         i = ceiling( spring_sfmt_stream() * nalph )

! determine its neighbour
         if ( spring_sfmt_stream() > half ) then
             j = i + 1
         else
             j = i - 1
         endif

! check the second alpha index
         if ( i == 1 ) j = i + 1
         if ( i == nalph ) j = i - 1

     else

! choose two alpha configuration randomly
         do while ( .true. )
             i = ceiling( spring_sfmt_stream() * nalph )
             j = ceiling( spring_sfmt_stream() * nalph )
             if ( i /= j ) EXIT
         enddo ! over do while loop

     endif ! back if ( scheme == 1 ) block

! calculate the da and dh
     da = alpha(i) - alpha(j)
     dh = hamil(i) - hamil(j)

! evaluate the transition probability
     pass = ( exp( da * dh ) > spring_sfmt_stream() )

! if this update action is accepted, swap two configurations
! and hamiltonian is also recalculated
     if ( pass .eqv. .true. ) then
         call iswap(ngamm, igamm(i, :),    igamm(j, :)   )
         call dswap(ngamm, rgamm(i, :), 1, rgamm(j, :), 1)

         call sac_make_hamil0( rgamm(i,:), igamm(i,:), hc )
         call sac_make_hamil1( hc, hamil(i) )

         call sac_make_hamil0( rgamm(j,:), igamm(j,:), hc )
         call sac_make_hamil1( hc, hamil(j) )
     endif ! back if ( pass .eqv. .true. ) block

! update the accept/reject statistics
     swap_tcount(i) = swap_tcount(i) + one
     swap_tcount(j) = swap_tcount(j) + one
     if ( pass .eqv. .true. ) then
         swap_accept(i) = swap_accept(i) + one
         swap_accept(j) = swap_accept(j) + one
     else
         swap_reject(i) = swap_reject(i) + one
         swap_reject(j) = swap_reject(j) + one
     endif ! back if ( pass .eqv. .true. ) block

     return

  contains

!>>> extended BLAS subroutines, exchange two integer vectors
  pure subroutine iswap(n, ix, iy)
     implicit none

! external arguments
! dimension of integer vector
     integer, intent(in) :: n

! integer vector X
     integer, intent(inout) :: ix(n)

! integer vector Y
     integer, intent(inout) :: iy(n)

! local variables
! dummy integer vector
     integer :: it(n)

     it = ix
     ix = iy
     iy = it

     return
  end subroutine iswap

  end subroutine sac_make_swap
