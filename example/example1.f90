program example1
!! Explicit ODR job, with user-supplied analytic derivatives and nondefault ifixx.
   use odrpack
   use odrpack_kinds, only: wp
   implicit none

   ! Variable declarations
   integer :: i, info, iprint, j, job, lunerr, lunrpt, m, n, np, nq
   integer, allocatable :: ifixx(:, :)
   real(kind=wp), allocatable :: beta(:), x(:, :), y(:, :)
   external :: fcn

   ! Set up report files
   lunerr = 9
   lunrpt = 9
   open (unit=9, file='./example/report1.dat')

   ! Read problem dimensions
   open (unit=5, file='./example/data1.dat')
   read (5, *) n, m, np, nq

   ! Allocate arrays
   allocate (beta(np), x(n, m), y(n, nq), ifixx(n, m))

   ! Read problem data and set nondefault value for argument 'ifixx'
   read (5, *) (beta(i), i=1, np)
   do i = 1, n
      read (5, *) (x(i, j), j=1, m), (y(i, j), j=1, nq)
      if (x(i, 1) .eq. 0.0E0_wp .or. x(i, 1) .eq. 100.0E0_wp) then
         ifixx(i, 1) = 0
      else
         ifixx(i, 1) = 1
      end if
   end do

   ! Specify task: Explicit orthogonal distance regression
   !       With user supplied derivatives (checked)
   !       Covariance matrix constructed with recomputed derivatives
   !       Delta initialized to zero
   !       Not a restart
   ! And indicate short initial report
   !       Short iteration reports every iteration, and
   !       Long final report
   job = 00020
   iprint = 1112

   ! Compute solution
   call odr(fcn=fcn, &
            n=n, m=m, np=np, nq=nq, &
            beta=beta, &
            y=y, x=x, &
            ifixx=ifixx, &
            job=job, &
            iprint=iprint, lunerr=lunerr, lunrpt=lunrpt, &
            info=info)

end program example1

subroutine fcn(n, m, np, nq, ldn, ldm, ldnp, beta, xplusd, ifixb, ifixx, &
               ldifx, ideval, f, fjacb, fjacd, istop)

   use odrpack_kinds, only: wp, zero, one
   implicit none

   integer, intent(in) :: ideval, ldifx, ldm, ldn, ldnp, m, n, np, nq
   integer, intent(in) :: ifixb(np), ifixx(ldifx, m)
   real(kind=wp), intent(in) :: beta(np), xplusd(ldn, m)
   real(kind=wp), intent(out) :: f(ldn, nq), fjacb(ldn, ldnp, nq), fjacd(ldn, ldm, nq)
   integer, intent(out) :: istop

   ! Local variables
   integer :: i

   ! Check for unacceptable values for this problem
   if (beta(1) .lt. zero) then
      istop = 1
      return
   else
      istop = 0
   end if

   ! Compute predicted values
   if (mod(ideval, 10) .ge. 1) then
      do i = 1, nq
         f(:, i) = beta(1) + beta(2)*(exp(beta(3)*xplusd(:, 1)) - one)**2
      end do
   end if

   ! Compute derivatives with respect to 'beta'
   if (mod(ideval/10, 10) .ge. 1) then
      do i = 1, nq
         fjacb(:, 1, i) = one
         fjacb(:, 2, i) = (exp(beta(3)*xplusd(:, 1)) - one)**2
         fjacb(:, 3, i) = beta(2)*2*(exp(beta(3)*xplusd(:, 1)) - one)*exp(beta(3)*xplusd(:, 1))*xplusd(:, 1)
      end do
   end if

   ! Compute derivatives with respect to 'delta'
   if (mod(ideval/100, 10) .ge. 1) then
      do i = 1, nq
         fjacd(:, 1, i) = beta(2)*2*(exp(beta(3)*xplusd(:, 1)) - one)*exp(beta(3)*xplusd(:, 1))*beta(3)
      end do
   end if

end subroutine fcn
