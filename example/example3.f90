program example3

   use odrpack
   use odrpack_kinds, only: wp
   implicit none

! Variable declarations
   integer :: i, info, iprint, j, job, lunerr, lunrpt, m, n, np, nq
   integer, allocatable :: ifixx(:, :)
   real(kind=wp), allocatable :: beta(:), x(:, :), y(:, :), wd(:, :, :), we(:, :, :)
   real(kind=wp), pointer :: delta(:, :)
   external :: fcn

! Set up ODRPACK95 report files
   lunerr = 9
   lunrpt = 9
   open (unit=9, file='./example/report3.dat')

! Read problem data: dimensions
   open (unit=5, file='./example/data3.dat')
   read (5, fmt=*) n, m, np, nq

! Allocate arrays
   allocate (beta(np), x(n, m), y(n, nq), delta(n, m), we(n, nq, nq), wd(n, m, m), ifixx(n, m))
   we(1, 1, 1) = -1.0E0_wp
   wd(1, 1, 1) = -1.0E0_wp
   ifixx(1, 1) = -1

! Read problem data: values
   read (5, fmt=*) (beta(i), i=1, np)
   do i = 1, n
      read (5, fmt=*) (x(i, j), j=1, m), (y(i, j), j=1, nq)
   end do

! Specify task as explicit orthogonal distance regression
!       With central difference derivatives
!       Covariance matrix constructed with recomputed derivatives
!       DELTA initialized by user
!       Not a restart
! And indicate long initial report
!       No iteration reports
!       Long final report
   job = 01010
   iprint = 2002

! Initialize DELTA, and specify first decade of frequencies as fixed
   do i = 1, n
      if (x(i, 1) .lt. 100.0E0_wp) then
         delta(i, 1) = 0.0E0_wp
         ifixx(i, 1) = 0
      elseif (x(i, 1) .le. 150.0E0_wp) then
         delta(i, 1) = 0.0E0_wp
         ifixx(i, 1) = 1
      elseif (x(i, 1) .le. 1000.0E0_wp) then
         delta(i, 1) = 25.0E0_wp
         ifixx(i, 1) = 1
      elseif (x(i, 1) .le. 10000.0E0_wp) then
         delta(i, 1) = 560.0E0_wp
         ifixx(i, 1) = 1
      elseif (x(i, 1) .le. 100000.0E0_wp) then
         delta(i, 1) = 9500.0E0_wp
         ifixx(i, 1) = 1
      else
         delta(i, 1) = 144000.0E0_wp
         ifixx(i, 1) = 1
      end if
   end do

! Set weights
   do i = 1, n
      if (x(i, 1) .eq. 100.0E0_wp .or. x(i, 1) .eq. 150.0E0_wp) then
         we(i, 1, 1) = 0.0E0_wp
         we(i, 1, 2) = 0.0E0_wp
         we(i, 2, 1) = 0.0E0_wp
         we(i, 2, 2) = 0.0E0_wp
      else
         we(i, 1, 1) = 559.6E0_wp
         we(i, 1, 2) = -1634.0E0_wp
         we(i, 2, 1) = -1634.0E0_wp
         we(i, 2, 2) = 8397.0E0_wp
      end if
      wd(i, 1, 1) = (1.0E-4_wp)/(x(i, 1)**2)
   end do

! Compute solution
   call odr(fcn=fcn, &
            n=n, m=m, np=np, nq=nq, &
            beta=beta, &
            y=y, x=x, &
            delta=delta, &
            we=we, wd=wd, &
            ifixx=ifixx, &
            job=job, &
            iprint=iprint, lunerr=lunerr, lunrpt=lunrpt, &
            info=info)

end program example3

subroutine fcn(n, m, np, nq, ldn, ldm, ldnp, beta, xplusd, ifixb, ifixx, &
               ldifx, ideval, f, fjacb, fjacd, istop)

   use odrpack_kinds, only: wp, one, zero
   implicit none

   integer, intent(in) :: ideval, ldifx, ldm, ldn, ldnp, m, n, np, nq
   integer, intent(in) :: ifixb(np), ifixx(ldifx, m)
   real(kind=wp), intent(in) :: beta(np), xplusd(ldn, m)
   real(kind=wp), intent(out) :: f(ldn, nq), fjacb(ldn, ldnp, nq), fjacd(ldn, ldm, nq)
   integer, intent(out) :: istop

! Local variables
   real(kind=wp) :: freq, omega, ctheta, stheta, theta, phi, r
   real(kind=wp), parameter :: pi = 4*atan(one)
   integer :: i

! Check for unacceptable values for this problem
   do i = 1, n
      if (xplusd(i, 1) .lt. zero) then
         istop = 1
         return
      end if
   end do
   istop = 0

   theta = pi*beta(4)*0.5E0_wp
   ctheta = cos(theta)
   stheta = sin(theta)

! Compute predicted values
   if (mod(ideval, 10) .ge. 1) then
      do i = 1, n
         freq = xplusd(i, 1)
         omega = (2.0E0_wp*pi*freq*exp(-beta(3)))**beta(4)
         phi = atan2((omega*stheta), (1 + omega*ctheta))
         r = (beta(1) - beta(2))*sqrt((1 + omega*ctheta)**2 + (omega*stheta)** &
                                      2)**(-beta(5))
         f(i, 1) = beta(2) + r*cos(beta(5)*phi)
         f(i, 2) = r*sin(beta(5)*phi)
      end do
   end if

end subroutine fcn
