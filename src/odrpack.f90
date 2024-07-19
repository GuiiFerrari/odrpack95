module odrpack

   use odrpack_kinds, only: wp
   implicit none

contains

   impure subroutine odr &
      (fcn, &
       n, m, np, nq, &
       beta, &
       y, x, &
       delta, &
       we, wd, &
       ifixb, ifixx, &
       job, ndigit, taufac, &
       sstol, partol, maxit, &
       iprint, lunerr, lunrpt, &
       stpb, stpd, &
       sclb, scld, &
       work, iwork, &
       info, &
       lower, upper)
   !! Driver routine for finding the weighted explicit or implicit orthogonal distance
   !! regression (ODR) or ordinary linear or nonlinear least squares (OLS) solution (long call
   !! statement).
      ! Date Written:   860529   (YYMMDD)
      ! Revision Date:  20040301 (YYYYMMDD)
      ! Category No.:  G2E,I1B1
      ! Keywords:  Orthogonal distance regression,
      !   Nonlinear least squares,
      !   Measurement error models,
      !   Errors in variables
      ! Authors:
      !   Boggs, Paul T.
      !     Applied and Computational Mathematics Division
      !     National Institute of Standards and Technology
      !     Gaithersburg, MD 20899
      !   Byrd, Richard H.
      !     Department of Computer Science
      !     University of Colorado, Boulder, CO 80309
      !   Rogers, Janet E.
      !     Applied and Computational Mathematics Division
      !     National Institute of Standards and Technology
      !     Boulder, CO 80303-3328
      !   Schnabel, Robert B.
      !     Department of Computer Science
      !     University of Colorado, Boulder, CO 80309
      !     and
      !     Applied and Computational Mathematics Division
      !     National Institute of Standards and Technology
      !     Boulder, CO 80303-3328
      ! Purpose:  REAL(wp) driver routine for finding the weighted explicit or implicit
      !   orthogonal distance regression (ODR) or ordinary linear or nonlinear least squares (OLS)
      !   solution (long call statement)
      ! Description:
      !   For details, see ODRPACK95 User's Reference Guide.
      ! References:
      !   Boggs, P. T., R. H. Byrd, J. R. Donaldson, and R. B. Schnabel (1989),
      !     "Algorithm 676 --- ODRPACK: Software for Weighted Orthogonal Distance Regression,"
      !     ACM Trans. Math. Software., 15(4):348-364.
      !       Boggs, P. T., R. H. Byrd, J. E. Rogers, and
      !   R. B. Schnabel (1992),
      !     "User's Reference Guide for ODRPACK Version 2.01,
      !     Software for Weighted Orthogonal Distance Regression,"
      !     National Institute of Standards and Technology
      !     Internal Report Number 92-4834.
      !  Boggs, P. T., R. H. Byrd, and R. B. Schnabel (1987),
      !    "A Stable and Efficient Algorithm for Nonlinear Orthogonal Distance Regression,"
      !    SIAM J. Sci. Stat. Comput., 8(6):1052-1078.

      use odrpack_kinds, only: negone, zero
      use odrpack_core, only: fcn_t

      procedure(fcn_t) :: fcn
         !! User-supplied subroutine for evaluating the model.
      integer, intent(in) :: n
         !! Number of observations.
      integer, intent(in) :: m
         !! Number of columns of data in the independent variable.
      integer, intent(in) :: np
         !! Number of function parameters.
      integer, intent(in) :: nq
         !! Number of responses per observation.
      real(wp), intent(inout) :: beta(:)
         !! Function parameters. `Shape: (np)`.
      real(wp), intent(in) :: y(:, :)
         !! Dependent variable. `Shape: (n, nq)`. Unused when the model is implicit.
      real(wp), intent(in) :: x(:, :)
         !! Explanatory variable. `Shape: (n, m)`.
      real(wp), intent(inout), optional :: delta(:, :)
         !! Initial error in the `x` data. `Shape: (n, m)`.
      real(wp), intent(in), optional :: we(:, :, :)
         !! `epsilon` weights. `Shape: (1<=ldwe<=n, 1<=ld2we<=nq, nq)`. See p. 25.
      real(wp), intent(in), optional :: wd(:, :, :)
         !! `delta` weights. `Shape: (1<=ldwd<=n, 1<=ld2wd<=m, m)`. See p. 26.
      integer, intent(in), optional :: ifixb(:)
         !! Values designating whether the elements of `beta` are fixed at their input values
         !! or not. `Shape: (np)`.
      integer, intent(in), optional :: ifixx(:, :)
         !! Values designating whether the elements of `x` are fixed at their input values
         !! or not. `Shape: (1<=ldifx<=n, m)`. See p. 27.
      integer, intent(in), optional :: job
         !! Variable controlling problem initialization and computational method.
      integer, intent(in), optional :: ndigit
         !! Number of accurate digits in the function results, as supplied by the user.
      real(wp), intent(in), optional :: taufac
         !! Factor used to compute the initial trust region diameter.
      real(wp), intent(in), optional :: sstol
         !! Sum-of-squares convergence stopping tolerance.
      real(wp), intent(in), optional :: partol
      !! Parameter convergence stopping tolerance.
      integer, intent(in), optional :: maxit
         !! Maximum number of iterations allowed.
      integer, intent(in), optional :: iprint
         !! Print control variable.
      integer, intent(in), optional :: lunerr
         !! Logical unit number for error messages.
      integer, intent(in), optional :: lunrpt
         !! Logical unit number for computation reports.
      real(wp), intent(in), optional :: stpb(:)
         !! Relative step for computing finite difference derivatives with respect to `beta`.
         !! `Shape: (np)`.
      real(wp), intent(in), optional :: stpd(:, :)
         !! Relative step for computing finite difference derivatives with respect to `delta`.
         !! `Shape: (1<=ldstpd<=n, m)`. See p. 31.
      real(wp), intent(in), optional :: sclb(:)
      !! Scaling values for `beta`. `Shape: (np)`.
      real(wp), intent(in), optional :: scld(:, :)
         !! Scaling values for `delta`. `Shape: (1<=ldscld<=n, m)`. See p. 32.
      real(wp), intent(inout), pointer, optional :: work(:)
         !! Real work space.
      integer, intent(inout), pointer, optional :: iwork(:)
         !! Integer work space.
      integer, intent(out), optional :: info
         !! Variable designating why the computations were stopped.
      real(wp), intent(in), optional :: lower(:)
         !! Lower bound on `beta`. `Shape: (np)`.
      real(wp), intent(in), optional :: upper(:)
         !! Upper bound on `beta`. `Shape: (np)`.

      ! Local variables
      ! TODO: remove save? replace pointer with allocatable?
      integer :: ldwe, ld2we, ldwd, ld2wd, ldifx, ldscld, ldstpd, ljob, lndigit, lmaxit, &
                 liprint, llunerr, llunrpt, linfo, lenwork, leniwork, linfo1, linfo2, linfo3, &
                 linfo4, linfo5
      integer :: lifixb(np), lifixx(n, m)
      real(wp) :: ltaufac, lsstol, lpartol
      real(wp) :: llower(np), lwe(n, nq, nq), lwd(n, m, m), lstpb(np), lstpd(n, m), &
                  lsclb(np), lscld(n, m), lupper(np), wd1(1, 1, 1)
      real(wp), allocatable :: tempret(:, :)

      real(wp), pointer, save :: lwork(:)
      integer, pointer, save :: liwork(:)
      logical :: head

      ! External ODRPACK procedures
      ! @todo: place in module
      external :: dodphd, dodpe1

      ! Set LINFO to zero indicating no errors have been found thus far
      linfo = 0
      linfo1 = 0
      linfo2 = 0
      linfo3 = 0
      linfo4 = 0
      linfo5 = 0

      ! Set all scalar variable defaults except JOB
      ldwe = 1
      ld2we = 1
      ldwd = 1
      ld2wd = 1
      ldifx = 1
      ldscld = 1
      ldstpd = 1
      liprint = -1
      llunerr = -1
      llunrpt = -1
      lmaxit = -1
      lndigit = -1
      lpartol = negone
      lsstol = negone
      ltaufac = negone
      head = .true.

      !  Check for the option arguments for printing (so error messages can be
      !  printed appropriately from here on out
      if (present(iprint)) then
         liprint = iprint
      end if

      if (present(lunrpt)) then
         llunrpt = lunrpt
      end if
      if (llunrpt < 0) then
         llunrpt = 6
      end if

      if (present(lunerr)) then
         llunerr = lunerr
      end if
      if (llunerr < 0) then
         llunerr = 6
      end if

      ! Ensure the problem size is valid
      if (n <= 0) then
         linfo5 = 1
         linfo4 = 1
      end if

      if (m <= 0) then
         linfo5 = 1
         linfo3 = 1
      end if

      if (np <= 0) then
         linfo5 = 1
         linfo2 = 1
      end if

      if (nq <= 0) then
         linfo5 = 1
         linfo1 = 1
      end if

      if (linfo5 /= 0) then
         linfo = 10000*linfo5 + 1000*linfo4 + 100*linfo3 + 10*linfo2 + linfo1
         if (llunerr > 0 .and. liprint /= 0) then
            call dodphd(head, llunrpt)
            call dodpe1( &
               llunerr, linfo, linfo5, linfo4, linfo3, linfo2, linfo1, &
               n, m, nq, &
               ldscld, ldstpd, ldwe, ld2we, ldwd, ld2wd, &
               lenwork, leniwork &
               )
         end if
         if (present(info)) then
            info = linfo
         end if
         return
      end if

      ! Define LJOB and check that necessary arguments are passed for JOB
      if (present(job)) then
         ljob = job
         if (mod(job, 10000)/1000 >= 1) then
            if (.not. present(delta)) then
               linfo5 = 7
               linfo4 = 1
               ! elseif (.not. allocated(delta)) then
               !    linfo5 = 7
               !    linfo4 = 1
            end if
         end if
         if (job >= 10000) then
            if (.not. present(iwork)) then
               linfo5 = 7
               linfo2 = 1
            elseif (.not. associated(iwork)) then
               linfo5 = 7
               linfo2 = 1
            end if
         end if
         if (job >= 10000) then
            if (.not. present(work)) then
               linfo5 = 7
               linfo3 = 1
            elseif (.not. associated(work)) then
               linfo5 = 7
               linfo3 = 1
            end if
         end if
      else
         ljob = -1
      end if

      if (linfo5 /= 0) then
         linfo = 10000*linfo5 + 1000*linfo4 + 100*linfo3 + 10*linfo2 + linfo1
         if (llunerr > 0 .and. liprint /= 0) then
            call dodphd(head, llunrpt)
            call dodpe1( &
               llunerr, linfo, linfo5, linfo4, linfo3, linfo2, linfo1, &
               n, m, nq, &
               ldscld, ldstpd, ldwe, ld2we, ldwd, ld2wd, &
               lenwork, leniwork &
               )
         end if
         if (present(info)) then
            info = linfo
         end if
         return
      end if

      ! Determine the size of WORK
      if (ljob < 0 .or. mod(ljob, 10) <= 1) then
         lenwork = 18 + 13*np + np**2 + m + m**2 + 4*n*nq + 6*n*m + 2*n*nq*np + &
                   2*n*nq*m + nq**2 + 5*nq + nq*(np + m) + n*nq*nq
      else
         lenwork = 18 + 13*np + np**2 + m + m**2 + 4*n*nq + 2*n*m + 2*n*nq*np + &
                   5*nq + nq*(np + m) + n*nq*nq
      end if

      ! Determine the size of IWORK
      leniwork = 20 + 2*np + nq*(np + m)

      ! Allocate the work arrays
      allocate (lwork(lenwork), tempret(max(n, np), max(nq, m)), stat=linfo3)
      allocate (liwork(leniwork), stat=linfo2)
      lwork = zero
      liwork = 0
      ! if (present(delta)) then
      !    if (.not. allocated(delta)) then
      !       allocate (delta(n, m), stat=linfo4)
      !    end if
      ! end if
      if (linfo4 /= 0 .or. linfo3 /= 0 .or. linfo2 /= 0) then
         linfo5 = 8
      end if

      if (linfo5 /= 0) then
         linfo = 10000*mod(linfo5, 10) + 1000*mod(linfo4, 10) + &
                 100*mod(linfo3, 10) + 10*mod(linfo2, 10) + mod(linfo1, 10)
         if (llunerr > 0 .and. liprint /= 0) then
            call dodphd(head, llunrpt)
            call dodpe1( &
               llunerr, linfo, linfo5, linfo4, linfo3, linfo2, linfo1, &
               n, m, nq, &
               ldscld, ldstpd, ldwe, ld2we, ldwd, ld2wd, &
               lenwork, leniwork)
         end if
         if (present(info)) then
            info = linfo
         end if
         return
      end if

      ! Set array variable defaults except IWORK
      lwork(1:n*m) = zero
      lifixb(1) = -1
      lifixx(1, 1) = -1
      llower(1:np) = -huge(zero)
      lsclb(1) = negone
      lscld(1, 1) = negone
      lstpb(1) = negone
      lstpd(1, 1) = negone
      lupper(1:np) = huge(zero)
      lwe(1, 1, 1) = negone
      lwd(1, 1, 1) = negone

      ! Check the size of required arguments and return errors if they are too small
      if (size(beta) < np) then
         linfo1 = linfo1 + 1
      end if

      if (any(size(y) < (/n, nq/))) then
         linfo1 = linfo1 + 2
      end if

      if (any(size(x) < (/n, m/))) then
         linfo1 = linfo1 + 4
      end if

      ! Check the presence of optional arguments and copy their values internally or
      ! report errors as necessary
      if (present(ifixb)) then
         if (size(ifixb) < np) then
            linfo1 = linfo1 + 64
         end if
         if (ifixb(1) < 0) then
            lifixb(1) = ifixb(1)
         else
            lifixb(1:np) = ifixb(1:np)
         end if
      end if

      if (present(ifixx)) then
         ldifx = size(ifixx, 1)
         if (any(size(ifixx) <= (/0, 0/))) then
            linfo1 = linfo1 + 128
         end if
         if (.not. (ifixx(1, 1) < 0 .or. ldifx == 1 .or. ldifx >= n) &
             .or. size(ifixx, 2) < m) then
            linfo1 = linfo1 + 128
         end if
         if (ldifx > n) then
            ldifx = n
         end if
         if (ifixx(1, 1) < 0) then
            lifixx(1, 1) = ifixx(1, 1)
         else
            lifixx(1:ldifx, 1:m) = ifixx(1:ldifx, 1:m)
         end if
      end if

      if (present(iwork)) then
         if (associated(iwork)) then
            if (size(iwork) < leniwork) then
               linfo1 = linfo1 + 8192
            end if
            !  This is a restart, copy IWORK.
            if (mod(ljob/10000, 10) >= 1) then
               liwork(1:leniwork) = iwork(1:leniwork)
            end if
         end if
      end if

      if (present(maxit)) then
         lmaxit = maxit
      end if

      if (present(ndigit)) then
         lndigit = ndigit
      end if

      if (present(partol)) then
         lpartol = partol
      end if

      if (present(sclb)) then
         if (size(sclb) < np) then
            linfo1 = linfo1 + 1024
         end if
         if (sclb(1) <= zero) then
            lsclb(1) = sclb(1)
         else
            lsclb(1:np) = sclb(1:np)
         end if
      end if

      if (present(scld)) then
         ldscld = size(scld, 1)
         if (any(size(scld) <= (/0, 0/))) then
            linfo1 = linfo1 + 2048
         end if
         if (.not. (scld(1, 1) <= zero .or. ldscld == 1 .or. ldscld >= n) &
             .or. size(scld, 2) < m) then
            linfo1 = linfo1 + 2048
         end if
         if (ldscld > n) then
            ldscld = n
         end if
         if (scld(1, 1) <= zero) then
            lscld(1, 1) = scld(1, 1)
         else
            lscld(1:ldscld, 1:m) = scld(1:ldscld, 1:m)
         end if
      end if

      if (present(sstol)) then
         lsstol = sstol
      end if

      if (present(stpb)) then
         if (size(stpb) < np) then
            linfo1 = linfo1 + 256
         end if
         if (stpb(1) <= zero) then
            lstpb(1) = stpb(1)
         else
            lstpb(1:np) = stpb(1:np)
         end if
      end if

      if (present(stpd)) then
         ldstpd = size(stpd, 1)
         if (any(size(stpd) <= (/0, 0/))) then
            linfo1 = linfo1 + 512
         end if
         if (.not. (stpd(1, 1) <= zero .or. ldstpd == 1 .or. ldstpd >= n) &
             .or. size(stpd, 2) < m) then
            linfo1 = linfo1 + 512
         end if
         if (ldstpd > n) then
            ldstpd = n
         end if
         if (stpd(1, 1) <= zero) then
            lstpd(1, 1) = stpd(1, 1)
         else
            lstpd(1:ldstpd, 1:m) = stpd(1:ldstpd, 1:m)
         end if
      end if

      if (present(taufac)) then
         ltaufac = taufac
      end if

      if (present(we)) then
         ldwe = size(we, 1)
         ld2we = size(we, 2)
         if (any(size(we) <= (/0, 0, 0/))) then
            linfo1 = linfo1 + 16
         end if
         if (.not. (we(1, 1, 1) < zero .or. &
                    ((ldwe == 1 .or. ldwe >= n) .and. &
                     (ld2we == 1 .or. ld2we >= nq))) .or. size(we, 3) < nq) then
            linfo1 = linfo1 + 16
         end if
         if (ldwe > n) then
            ldwe = n
         end if
         if (ld2we > nq) then
            ld2we = nq
         end if
         if (we(1, 1, 1) < zero) then
            lwe(1, 1, 1) = we(1, 1, 1)
         else
            lwe(1:ldwe, 1:ld2we, 1:nq) = we(1:ldwe, 1:ld2we, 1:nq)
         end if
      end if

      if (present(wd)) then
         ldwd = size(wd, 1)
         ld2wd = size(wd, 2)
         if (any(size(wd) <= (/0, 0, 0/))) then
            linfo1 = linfo1 + 32
         end if
         if (.not. (wd(1, 1, 1) < zero .or. &
                    ((ldwd == 1 .or. ldwd >= n) .and. &
                     (ld2wd == 1 .or. ld2wd >= m))) .or. size(wd, 3) < m) then
            linfo1 = linfo1 + 32
         end if
         if (ldwd > n) then
            ldwd = n
         end if
         if (ld2wd > m) then
            ld2wd = m
         end if
         if (wd(1, 1, 1) <= 0.0_wp) then
            lwd(1, 1, 1) = wd(1, 1, 1)
         else
            lwd(1:ldwd, 1:ld2wd, 1:m) = wd(1:ldwd, 1:ld2wd, 1:m)
         end if
      end if

      if (present(work)) then
         if (associated(work)) then
            if (size(work) < lenwork) then
               linfo1 = linfo1 + 4096
            end if
            !  Deltas are in WORK, copy them.
            if (mod(ljob/1000, 10) >= 1 .and. .not. present(delta)) then
               lwork(1:n*m) = work(1:n*m)
            end if
            !  This is a restart, copy WORK.
            if (mod(ljob/10000, 10) >= 1) then
               lwork(1:lenwork) = work(1:lenwork)
            end if
         end if
      end if

      if (present(delta)) then
         !if (allocated(delta)) then
         if (any(shape(delta) < (/n, m/))) then
            linfo1 = linfo1 + 8
         end if
         lwork(1:n*m) = reshape(delta(1:n, 1:m), (/n*m/))
         !end if
      end if

      if (present(lower)) then
         if (size(lower) < np) then
            linfo1 = linfo1 + 32768
         end if
         llower(1:np) = lower(1:np)
      end if

      if (present(upper)) then
         if (size(upper) < np) then
            linfo1 = linfo1 + 16384
         end if
         lupper(1:np) = upper(1:np)
      end if

      ! Report an error if any of the array sizes didn't match.
      if (linfo1 /= 0) then
         linfo = 100000 + linfo1
         linfo1 = 0
         if (llunerr > 0 .and. liprint /= 0) then
            call dodphd(head, llunrpt)
            call dodpe1( &
               llunerr, linfo, linfo5, linfo4, linfo3, linfo2, linfo1, &
               n, m, nq, &
               ldscld, ldstpd, ldwe, ld2we, ldwd, ld2wd, &
               lenwork, leniwork &
               )
         end if
         if (present(info)) then
            info = linfo
         end if
         return
      end if

      if (lwd(1, 1, 1) /= 0) then
         call dodcnt &
            (fcn, &
             n, m, np, nq, &
             beta(1:np), &
             y(1:n, 1:nq), n, x(1:n, 1:m), n, &
             lwe(1:ldwe, 1:ld2we, 1:nq), ldwe, ld2we, &
             lwd(1:ldwd, 1:ld2wd, 1:m), ldwd, ld2wd, &
             lifixb, lifixx(1:ldifx, 1:m), ldifx, &
             ljob, lndigit, ltaufac, &
             lsstol, lpartol, lmaxit, &
             liprint, llunerr, llunrpt, &
             lstpb, lstpd(1:ldstpd, 1:m), ldstpd, &
             lsclb, lscld(1:ldscld, 1:m), ldscld, &
             lwork, lenwork, tempret, liwork, leniwork, &
             linfo, &
             llower, lupper)
      else
         wd1(1, 1, 1) = negone
         call dodcnt &
            (fcn, &
             n, m, np, nq, &
             beta(1:np), &
             y(1:n, 1:nq), n, x(1:n, 1:m), n, &
             lwe(1:ldwe, 1:ld2we, 1:nq), ldwe, ld2we, &
             wd1, 1, 1, &
             lifixb, lifixx(1:ldifx, 1:m), ldifx, &
             ljob, lndigit, ltaufac, &
             lsstol, lpartol, lmaxit, &
             liprint, llunerr, llunrpt, &
             lstpb, lstpd(1:ldstpd, 1:m), ldstpd, &
             lsclb, lscld(1:ldscld, 1:m), ldscld, &
             lwork, lenwork, tempret, liwork, leniwork, &
             linfo, &
             llower, lupper)
      end if

      if (present(delta)) then
         !if (allocated(delta)) then
         delta(1:n, 1:m) = reshape(lwork(1:n*m), (/n, m/))
         !end if
      end if

      if (present(info)) then
         info = linfo
      end if

      if (present(iwork)) then
         if (.not. associated(iwork)) then
            iwork => liwork
         else
            iwork(1:leniwork) = liwork(1:leniwork)
            deallocate (liwork)
         end if
      else
         deallocate (liwork)
      end if

      if (present(work)) then
         if (.not. associated(work)) then
            work => lwork
         else
            work(1:lenwork) = lwork(1:lenwork)
            deallocate (lwork)
         end if
      else
         deallocate (lwork)
      end if

      deallocate (tempret)

   end subroutine odr

   impure subroutine dodcnt &
      (fcn, n, m, np, nq, beta, y, ldy, x, ldx, &
       we, ldwe, ld2we, wd, ldwd, ld2wd, ifixb, ifixx, ldifx, &
       job, ndigit, taufac, sstol, partol, maxit, iprint, lunerr, lunrpt, &
       stpb, stpd, ldstpd, sclb, scld, ldscld, &
       work, lwork, tempret, iwork, liwork, &
       info, &
       lower, upper)
   !! Driver routine for finding the weighted explicit or implicit orthogonal distance
   !! regression (ODR) or ordinary linear or nonlinear least squares (OLS) solution.
      ! Routines Called  DODDRV
      ! Date Written   860529   (YYMMDD)
      ! Revision Date  920304   (YYMMDD)

      use odrpack_kinds, only: zero, one, three
      use odrpack_core, only: fcn_t

      procedure(fcn_t) :: fcn
         !! User-supplied subroutine for evaluating the model.
      integer, intent(in) :: n
         !! The number of observations.
      integer, intent(in) :: m
         !! The number of columns of data in the independent variable.
      integer, intent(in) :: np
         !! The number of function parameters.
      integer, intent(in) :: nq
         !! The number of responses per observation.
      real(wp), intent(inout) :: beta(np)
         !! The function parameters.
      real(wp), intent(in) :: y(ldy, nq)
         !! The dependent variable. Unused when the model is implicit.
      integer, intent(in) :: ldy
         !! The leading dimension of array `y`.
      real(wp), intent(in) :: x(ldx, m)
         !! The independent variable.
      integer, intent(in) :: ldx
         !! The leading dimension of array `x`.
      real(wp), intent(inout) :: we(ldwe, ld2we, nq)
         !! The `epsilon` weights.
      integer, intent(in) :: ldwe
         !! The leading dimension of array `we`.
      integer, intent(in) :: ld2we
         !! The second dimension of array `we`.
      real(wp), intent(in) :: wd(ldwd, ld2wd, m)
         !! The `delta` weights.
      integer, intent(in) :: ldwd
         !! The leading dimension of array `wd`.
      integer, intent(in) :: ld2wd
         !! The second dimension of array `wd`.
      integer, intent(in) :: ifixb(np)
         !! The values designating whether the elements of `beta` are fixed at their input
         !! values or not.
      integer, intent(in) :: ifixx(ldifx, m)
         !! The values designating whether the elements of `x` are fixed at their input values
         !! or not.
      integer, intent(in) :: ldifx
         !! The leading dimension of array `ifixx`.
      integer, intent(inout) :: job
         !! The variable controlling problem initialization and computational method.
      integer, intent(in) :: ndigit
         !! The number of accurate digits in the function results, as supplied by the user.
      real(wp), intent(in) :: taufac
         !! The factor used to compute the initial trust region diameter.
      real(wp), intent(in) :: sstol
         !! The sum-of-squares convergence stopping tolerance.
      real(wp), intent(in) :: partol
         !! The user-supplied parameter convergence stopping tolerance.
      integer, intent(in) :: maxit
         !! The maximum number of iterations allowed.
      integer, intent(in) :: iprint
         !! The print control variables.
      integer, intent(in) :: lunerr
         !! The logical unit number used for error messages.
      integer, intent(in) :: lunrpt
         !! The logical unit number used for computation reports.
      real(wp), intent(in) :: stpb(np)
         !! The relative step for computing finite difference derivatives with respect to `beta`.
      real(wp), intent(in) :: stpd(ldstpd, m)
         !! The relative step for computing finite difference derivatives with respect to `delta`.
      integer, intent(in) :: ldstpd
         !! The leading dimension of array `stpd`.
      real(wp), intent(in) :: sclb(np)
         !! The scaling values for `beta`.
      real(wp), intent(in) :: scld(ldscld, m)
         !! The scaling value for `delta`.
      integer, intent(in) :: ldscld
         !! The leading dimension of array `scld`.
      real(wp), intent(inout) :: work(lwork)
         !! The real work space.
      integer, intent(in) :: lwork
         !! The length of vector `work`.
      real(wp), intent(inout) :: tempret(:, :)
         !! Temporary work array for holding return values before copying to a lower rank array.
      integer, intent(inout) :: iwork(liwork)
         !! The integer work space.
      integer, intent(in) :: liwork
         !! The length of vector `iwork`.
      integer, intent(out) :: info
         !! The variable designating why the computations were stopped.
      real(wp), intent(in) :: lower(np)
         !! The lower bound on `beta`.
      real(wp), intent(in) :: upper(np)
         !! The upper bound on `beta`.

      ! Local scalars
      real(wp), parameter :: pcheck = 1.0E3_wp, pstart = 1.0E1_wp, pfac = 1.0E1_wp
      real(wp) :: cnvtol, tstimp
      integer :: iprnti, ipr1, ipr2, ipr2f, ipr3, jobi, job1, job2, job3, job4, job5, &
                 maxiti, maxit1
      logical :: done, fstitr, head, implct, prtpen

      ! Local arrays
      real(wp) :: pnlty(1, 1, 1)

      ! Variable Definitions (alphabetically)
      !  BETA:    The function parameters.
      !  CNVTOL:  The convergence tolerance for implicit models.
      !  DONE:    The variable designating whether the inplicit solution has been found (DONE=TRUE)
      !           or not (DONE=FALSE).
      !  FCN:     The user-supplied subroutine for evaluating the model.
      !  FSTITR:  The variable designating whether this is the first iteration (FSTITR=TRUE)
      !           or not (FSTITR=FALSE).
      !  HEAD:    The variable designating whether the heading is to be printed (HEAD=TRUE)
      !           or not (HEAD=FALSE).
      !  IFIXB:   The values designating whether the elements of BETA are fixed at their input
      !           values or not.
      !  IFIXX:   The values designating whether the elements of X are fixed at their input
      !           values or not.
      !  IMPLCT:  The variable designating whether the solution is by implicit ODR (IMPLCT=TRUE)
      !           or explicit ODR (IMPLCT=FALSE).
      !  INFO:    The variable designating why the computations were stopped.
      !  IPRINT:  The print control variables.
      !  IPRNTI:  The print control variables.
      !  IPR1:    The 1st digit of the print control variable.
      !  IPR2:    The 2nd digit of the print control variable.
      !  IPR3:    The 3rd digit of the print control variable.
      !  IPR4:    The 4th digit of the print control variable.
      !  IWORK:   The integer work space.
      !  JOB:     The variable controling problem initialization and computational method.
      !  JOBI:    The variable controling problem initialization and computational method.
      !  JOB1:    The 1st digit of the variable JOB.
      !  JOB2:    The 2nd digit of the variable JOB.
      !  JOB3:    The 3rd digit of the variable JOB.
      !  JOB4:    The 4th digit of the variable JOB.
      !  JOB5:    The 5th digit of the variable JOB.
      !  LDIFX:   The leading dimension of array IFIXX.
      !  LDSCLD:  The leading dimension of array SCLD.
      !  LDSTPD:  The leading dimension of array STPD.
      !  LDWD:    The leading dimension of array WD.
      !  LDWE:    The leading dimension of array WE.
      !  LDX:     The leading dimension of array X.
      !  LDY:     The leading dimension of array Y.
      !  LD2WD:   The second dimension of array WD.
      !  LD2WE:   The second dimension of array WE.
      !  LIWORK:  The length of vector IWORK.
      !  LOWER:   The lower bound for BETA.
      !  LUNERR:  The logical unit number used for error messages.
      !  LUNRPT:  The logical unit number used for computation reports.
      !  LWORK:   The length of vector work.
      !  M:       The number of columns of data in the independent variable.
      !  MAXIT:   The maximum number of iterations allowed.
      !  MAXITI:  For implicit models, the number of iterations allowed for the current penalty
      !           parameter value.
      !  MAXIT1:  For implicit models, the number of iterations allowed for the next penalty
      !           parameter value.
      !  N:       The number of observations.
      !  NDIGIT:  The number of accurate digits in the function results, as supplied by the user.
      !  NP:      The number of function parameters.
      !  NQ:      The number of responses per observation.
      !  PARTOL:  The user supplied parameter convergence stopping tolerance.
      !  PCHECK:  The value designating the minimum penalty parameter allowed before the implicit
      !           problem can be considered solved.
      !  PFAC:    The factor for increasing the penalty parameter.
      !  PNLTY:   The penalty parameter for an implicit model.
      !  PRTPEN:  The value designating whether the penalty parameter is to be printed in the
      !           iteration report (PRTPEN=TRUE) or not (PRTPEN=FALSE).
      !  PSTART:  The factor for increasing the penalty parameter.
      !  SCLB:    The scaling values for BETA.
      !  SCLD:    The scaling values for DELTA.
      !  STPB:    The relative step for computing finite difference derivatives with respect to BETA.
      !  STPD:    The relative step for computing finite difference derivatives with respect to DELTA.
      !  SSTOL:   The sum-of-squares convergence stopping tolerance.
      !  TAUFAC:  The factor used to compute the initial trust region diameter.
      !  TSTIMP:  The relative change in the parameters between the initial values and the solution.
      !  UPPER:   The upper bound for BETA.
      !  WD:      The DELTA weights.
      !  WE:      The EPSILON weights.
      !  WORK:    The real work space.
      !  X:       The independent variable.
      !  Y:       The dependent variable. Unused when the model is implicit.

      implct = mod(job, 10) == 1
      fstitr = .true.
      head = .true.
      prtpen = .false.

      if (implct) then
         !  Set up for implicit problem
         if (iprint >= 0) then
            ipr1 = mod(iprint, 10000)/1000
            ipr2 = mod(iprint, 1000)/100
            ipr2f = mod(iprint, 100)/10
            ipr3 = mod(iprint, 10)
         else
            ipr1 = 2
            ipr2 = 0
            ipr2f = 0
            ipr3 = 1
         end if
         iprnti = ipr1*1000 + ipr2*100 + ipr2f*10

         job5 = mod(job, 100000)/10000
         job4 = mod(job, 10000)/1000
         job3 = mod(job, 1000)/100
         job2 = mod(job, 100)/10
         job1 = mod(job, 10)
         jobi = job5*10000 + job4*1000 + job3*100 + job2*10 + job1

         if (we(1, 1, 1) <= zero) then
            pnlty(1, 1, 1) = -pstart
         else
            pnlty(1, 1, 1) = -we(1, 1, 1)
         end if

         if (partol < zero) then
            cnvtol = epsilon(zero)**(one/three)
         else
            cnvtol = min(partol, one)
         end if

         if (maxit >= 1) then
            maxiti = maxit
         else
            maxiti = 100
         end if

         done = maxiti == 0
         prtpen = .true.

         do while (.true.)
            call doddrv &
               (head, fstitr, prtpen, &
                fcn, n, m, np, nq, beta, y, ldy, x, ldx, &
                pnlty, 1, 1, wd, ldwd, ld2wd, ifixb, ifixx, ldifx, &
                jobi, ndigit, taufac, sstol, cnvtol, maxiti, &
                iprnti, lunerr, lunrpt, &
                stpb, stpd, ldstpd, sclb, scld, ldscld, &
                work, lwork, tempret, iwork, liwork, &
                maxit1, tstimp, info, lower, upper)

            if (done) then
               return
            else
               done = maxit1 <= 0 .or. (abs(pnlty(1, 1, 1)) >= pcheck .and. tstimp <= cnvtol)
            end if

            if (done) then
               if (tstimp <= cnvtol) then
                  info = (info/10)*10 + 2
               else
                  info = (info/10)*10 + 4
               end if
               jobi = 10000 + 1000 + job3*100 + job2*10 + job1
               maxiti = 0
               iprnti = ipr3
            else
               prtpen = .true.
               pnlty(1, 1, 1) = pfac*pnlty(1, 1, 1)
               jobi = 10000 + 1000 + 000 + job2*10 + job1
               maxiti = maxit1
               iprnti = 0000 + ipr2*100 + ipr2f*10
            end if
         end do
      else
         ! Explicit problem
         call doddrv &
            (head, fstitr, prtpen, &
             fcn, n, m, np, nq, beta, y, ldy, x, ldx, &
             we, ldwe, ld2we, wd, ldwd, ld2wd, ifixb, ifixx, ldifx, &
             job, ndigit, taufac, sstol, partol, maxit, &
             iprint, lunerr, lunrpt, &
             stpb, stpd, ldstpd, sclb, scld, ldscld, &
             work, lwork, tempret, iwork, liwork, &
             maxit1, tstimp, info, lower, upper)
      end if

   end subroutine dodcnt

   impure subroutine doddrv &
      (head, fstitr, prtpen, &
       fcn, n, m, np, nq, beta, y, ldy, x, ldx, &
       we, ldwe, ld2we, wd, ldwd, ld2wd, ifixb, ifixx, ldifx, &
       job, ndigit, taufac, sstol, partol, maxit, &
       iprint, lunerr, lunrpt, &
       stpb, stpd, ldstpd, sclb, scld, ldscld, &
       work, lwork, tempret, iwork, liwork, &
       maxit1, tstimp, info, lower, upper)
   !! Performs error checking and initialization, and begins procedure for performing orthogonal
   !! distance regression (ODR) or ordinary linear or nonlinear least squares (OLS).
      ! Routines Called  FCN, DCOPY, DDOT, DETAF, DFCTRW, DFLAGS,
      !                  DINIWK, DIWINF, DJCK, DNRM2, DODCHK, DODMN,
      !                  DODPER, DPACK, DSETN, DUNPAC, DWGHT, DWINF, DERSTEP
      ! Date Written   860529   (YYMMDD)
      ! Revision Date  920619   (YYMMDD)

      use odrpack_kinds, only: zero, one, ten, p5 => half
      use odrpack_core, only: fcn_t, detaf, dfctrw, dflags, diniwk, diwinf, djck, dodchk, &
                              dpack, dsetn, dunpac, dwght, dwinf, derstep, mbfb

      logical, intent(in) :: head
         !! The variable designating whether the heading is to be printed (`head = .true.`)
         !! or not (`head = .false.`).
      logical, intent(inout) :: fstitr
         !! The variable designating whether this is the first iteration (`fstitr = .true.`)
         !! or not (`fstitr = .false.`).
      logical, intent(inout) :: prtpen
         !! The variable designating whether the penalty parameter is to be printed in the
         !! iteration report (`prtpen = .true.`) or not (`prtpen = .false.`).
      procedure(fcn_t) :: fcn
         !! The user-supplied subroutine for evaluating the model.
      integer, intent(in) :: n
         !! The number of observations.
      integer, intent(in) :: m
         !! The number of columns of data in the explanatory variable.
      integer, intent(in) :: np
         !! The number of function parameters.
      integer, intent(in) :: nq
         !! The number of responses per observation.
      real(wp), intent(inout) :: beta(np)
         !! The function parameters.
      real(wp), intent(in) :: y(ldy, nq)
         !! The dependent variable. Unused when the model is implicit.
      integer, intent(in) :: ldy
         !! The leading dimension of array `y`.
      real(wp), intent(in) :: x(ldx, m)
         !! The explanatory variable.
      integer, intent(in) :: ldx
         !! The leading dimension of array `x`.
      real(wp), intent(inout) :: we(ldwe, ld2we, nq)
         !! The `epsilon` weights.
      integer, intent(in) :: ldwe
         !! The leading dimension of array `we`.
      integer, intent(in) :: ld2we
         !! The second dimension of array `we`.
      real(wp), intent(in) :: wd(ldwd, ld2wd, m)
         !! The `delta`        weights.
      integer, intent(in) :: ldwd
         !! The leading dimension of array `wd`.
      integer, intent(in) :: ld2wd
         !! The second dimension of array `wd`.
      integer, intent(in) :: ifixb(np)
         !! The values designating whether the elements of `beta` are fixed at their input
         !! values or not.
      integer, intent(in) :: ifixx(ldifx, m)
         !! The values designating whether the elements of `x` are fixed at their input
         !! values or not.
      integer, intent(in) :: ldifx
         !! The leading dimension of array `ifixx`.
      integer, intent(inout) :: job
         !! The variable controlling problem initialization and computational method.
      integer, intent(in) :: ndigit
         !! The number of accurate digits in the function results, as supplied by the user.
      real(wp), intent(in) :: taufac
         !! The factor used to compute the initial trust region diameter.
      real(wp), intent(in) :: sstol
         !! The sum-of-squares convergence stopping tolerance.
      real(wp), intent(in) :: partol
         !! The parameter convergence stopping tolerance.
      integer, intent(in) :: maxit
         !! The maximum number of iterations allowed.
      integer, intent(in) :: iprint
         !! The print control variable.
      integer, intent(in) :: lunerr
         !! The logical unit number used for error messages.
      integer, intent(in) :: lunrpt
         !! The logical unit number used for computation reports.
      real(wp), intent(in) :: stpb(np)
         !! The step size for finite difference derivatives with respect to `beta`.
      real(wp), intent(in) :: stpd(ldstpd, m)
         !! The step size for finite difference derivatives with respect to `delta`.
      integer, intent(in) :: ldstpd
         !! The leading dimension of array `stpd`.
      real(wp), intent(in) :: sclb(np)
         !! The scaling values for `beta`.
      real(wp), intent(in) :: scld(ldscld, m)
         !! The scaling values for `delta`.
      integer, intent(in) :: ldscld
         !! The leading dimension of array `scld`.
      real(wp), intent(inout) :: work(lwork)
         !! The real work space.
      integer, intent(in) :: lwork
         !! The length of vector `work`.
      real(wp), intent(inout) :: tempret(:, :)
         !! Temporary work array for holding return values before copying to a lower rank array.
      integer, intent(inout) :: iwork(liwork)
         !! The integer work space.
      integer, intent(in) :: liwork
         !! The length of vector `iwork`.
      integer, intent(out) :: maxit1
         !! For implicit models, the iterations allowed for the next penalty parameter value.
      real(wp), intent(out) :: tstimp
         !! The relative change in the parameters between the initial values and the solution.
      integer, intent(inout) :: info
         !! The variable designating why the computations were stopped.
      real(wp), intent(in) :: lower(np)
         !! The lower bound for `beta`.
      real(wp), intent(in) :: upper(np)
         !! The upper bound for `beta`.

      ! Local scalars
      real(wp) :: epsmac, eta
      integer :: actrsi, alphai, betaci, betani, betasi, beta0i, boundi, deltai, &
                 deltni, deltsi, diffi, epsmai, etai, fi, fjacbi, fjacdi, fni, fsi, i, &
                 idfi, int2i, iprini, iranki, istop, istopi, jobi, jpvti, k, ldtt, &
                 ldtti, liwkmn, loweri, luneri, lunrpi, lwkmn, lwrk, maxiti, msgb, &
                 msgd, neta, netai, nfev, nfevi, niteri, njev, njevi, nnzw, nnzwi, &
                 npp, nppi, nrow, nrowi, ntol, ntoli, olmavi, omegai, partli, pnormi, &
                 prersi, qrauxi, rcondi, rnorsi, rvari, sdi, si, ssfi, ssi, sstoli, &
                 taufci, taui, ti, tti, ui, upperi, vcvi, we1i, wrk1i, wrk2i, wrk3i, &
                 wrk4i, wrk5i, wrk6i, wrk7i, wrk, wssi, wssdei, wssepi, xplusi
      logical :: anajac, cdjac, chkjac, dovcv, implct, initd, isodr, redoj, restrt

      ! Local arrays
      real(wp) :: betaj(np)
      integer :: interval(np)

      ! External BLAS/LAPACK procedures
      real(wp), external :: ddot, dnrm2
      external :: dcopy

      ! External ODRPACK procedures
      ! @todo: place in module
      external :: dodper

      ! Variable Definitions (alphabetically)
      !  ACTRSI:   The location in array work of variable ACTRS.
      !  ALPHAI:   The location in array work of variable ALPHA.
      !  ANAJAC:   The variable designating whether the Jacobians are computed by finite
      !            differences (ANAJAC=FALSE) or not (ANAJAC=TRUE).
      !  BETA:     The function parameters.
      !  BETACI:   The starting location in array WORK of array BETAC.
      !  BETAJ:    The parameters to use in the derivative checking algorithm.
      !  BETANI:   The starting location in array WORK of array BETAN.
      !  BETASI:   The starting location in array WORK of array BETAS.
      !  BETA0I:   The starting location in array WORK of array BETA0.
      !  CDJAC:    The variable designating whether the Jacobians are computed by central
      !            differences (CDJAC=TRUE) or forward differences (CDJAC=FALSE).
      !  CHKJAC:   The variable designating whether the user supplied Jacobians are to be
      !            checked (CHKJAC=TRUE) or not (CHKJAC=FALSE).
      !  DELTAI:   The starting location in array WORK of array DELTA.
      !  DELTNI:   The starting location in array WORK of array DELTAN.
      !  DELTSI:   The starting location in array WORK of array DELTAS.
      !  DIFFI:    The starting location in array WORK of array DIFF.
      !  DOVCV:    The variable designating whether the covariance matrix is to be computed
      !            (DOVCV=TRUE) or not (DOVCV=FALSE).
      !  EPSMAI:   The location in array WORK of variable EPSMAC.
      !  ETA:      The relative noise in the function results.
      !  ETAI:     The location in array WORK of variable ETA.
      !  FCN:      THE USER SUPPLIED SUBROUTINE FOR EVALUATING THE MODEL.
      !  FI:       The starting location in array WORK of array F.
      !  FJACBI:   The starting location in array WORK of array FJACB.
      !  FJACDI:   The starting location in array WORK of array FJACD.
      !  FNI:      The starting location in array WORK of array FN.
      !  FSI:      The starting location in array WORK of array FS.
      !  FSTITR:   The variable designating whether this is the first iteration (FSTITR=TRUE)
      !            or not (FSTITR=FALSE).
      !  HEAD:     The variable designating whether the heading is to be printed (HEAD=TRUE)
      !            or not (HEAD=FALSE).
      !  I:        An index variable.
      !  IDFI:     The location in array iwork of variable IDF.
      !  IFIXB:    The values designating whether the elements of BETA are fixed at their input
      !            values or not.
      !  IFIXX:    The values designating whether the elements of X are fixed at their input
      !            values or not.
      !  IMPLCT:   The variable designating whether the solution is by implicit ODR (IMPLCT=TRUE)
      !            or explicit ODR (IMPLCT=FALSE).
      !  INFO:     The variable designating why the computations were stopped.
      !  INITD:    The variable designating whether DELTA is to be initialized to zero (INITD=TRUE)
      !            or to the values in the first N by M elements of array WORK (INITD=FALSE).
      !  INT2I:    The location in array IWORK of variable INT2.
      !  INTERVAL: Specifies which checks can be performed when checking derivatives based on the
      !            interval of the bound constraints.
      !  IPRINI:   The location in array iwork of variable IPRINT.
      !  IPRINT:   The print control variable.
      !  IRANKI:   The location in array IWORK of variable IRANK.
      !  ISODR:    The variable designating whether the solution is by ODR (ISODR=TRUE)
      !            or by OLS (ISODR=FALSE).
      !  ISTOP:    The variable designating whether there are problems computing the function
      !            at the current BETA and DELTA.
      !  ISTOPI:   The location in array IWORK of variable ISTOP.
      !  IWORK:    The integer work space.
      !  JOB:      The variable controling problem initialization and computational method.
      !  JOBI:     The location in array IWORK of variable JOB.
      !  JPVTI:    The starting location in array IWORK of array JPVT.
      !  K:        An index variable.
      !  LDIFX:    The leading dimension of array IFIXX.
      !  LDSCLD:   The leading dimension of array SCLD.
      !  LDSTPD:   The leading dimension of array STPD.
      !  LDTT:     The leading dimension of array TT.
      !  LDTTI:    The location in array IWORK of variable LDTT.
      !  LDWD:     The leading dimension of array WD.
      !  LDWE:     The leading dimension of array WE.
      !  LDX:      The leading dimension of array X.
      !  LDY:      The leading dimension of array Y.
      !  LD2WD:    The second dimension of array WD.
      !  LD2WE:    The second dimension of array WE.
      !  LIWKMN:   The minimum acceptable length of array IWORK.
      !  LIWORK:   The length of vector IWORK.
      !  LOWER:    The lower bound for BETA.
      !  LUNERI:   The location in array IWORK of variable LUNERR.
      !  LUNERR:   The logical unit number used for error messages.
      !  LUNRPI:   The location in array IWORK of variable LUNRPT.
      !  LUNRPT:   The logical unit number used for computation reports.
      !  LWKMN:    The minimum acceptable length of array WORK.
      !  LWORK:    The length of vector WORK.
      !  LWRK:     The length of vector WRK.
      !  M:        The number of columns of data in the explanatory variable.
      !  MAXIT:    The maximum number of iterations allowed.
      !  MAXIT1:   For implicit models, the iterations allowed for the next penalty parameter value.
      !  MAXITI:   The location in array IWORK of variable MAXIT.
      !  MSGB:     The starting location in array IWORK of array MSGB.
      !  MSGD:     The starting location in ARRAY IWORK of array MSGD.
      !  N:        The number of observations.
      !  NDIGIT:   The number of accurate digits in the function results, as supplied by the user.
      !  NETA:     The number of accurate digits in the function results.
      !  NETAI:    The location in array IWORK of variable NETA.
      !  NFEV:     The number of function evaluations.
      !  NFEVI:    The location in array IWORK of variable NFEV.
      !  NITERI:   The location in array IWORK of variable NITER.
      !  NJEV:     The number of Jacobian evaluations.
      !  NJEVI:    The location in array IWORK of variable NJEV.
      !  NNZW:     The number of nonzero observational error weights.
      !  NNZWI:    The location in array IWORK of variable NNZW.
      !  NP:       The number of function parameters.
      !  NPP:      The number of function parameters being estimated.
      !  NPPI:     The location in array IWORK of variable NPP.
      !  NQ:       The number of responses per observation.
      !  NROW:     The row number at which the derivative is to be checked.
      !  NROWI:    The location in array IWORK of variable NROW.
      !  NTOL:     The number of digits of agreement required between the numerical derivatives
      !            and the user supplied derivatives, set by DJCK.
      !  NTOLI:    The location in array IWORK of variable NTOL.
      !  OLMAVI:   The location in array WORK of variable OLMAVG.
      !  OMEGAI:   The starting location in array WORK of array OMEGA.
      !  PARTLI:   The location in array WORK of variable PARTOL.
      !  PARTOL:   The parameter convergence stopping tolerance.
      !  PNORM:    The norm of the scaled estimated parameters.
      !  PNORMI:   The location in array WORK of variable PNORM.
      !  PRERSI:   The location in array WORK of variable PRERS.
      !  PRTPEN:   The variable designating whether the penalty parameter is to be printed in
      !            the iteration report (PRTPEN=TRUE) or not (PRTPEN=FALSE).
      !  QRAUXI:   The starting location in array WORK of array QRAUX.
      !  RCONDI:   The location in array WORK of variable RCOND.
      !  REDOJ:    The variable designating whether the Jacobian matrix is to be recomputed for
      !            the computation of the covariance matrix (REDOJ=TRUE) or not (REDOJ=FALSE).
      !  RESTRT:   The variable designating whether the call is a restart (RESTRT=TRUE) or
      !            not (RESTRT=FALSE).
      !  RNORSI:   The location in array WORK of variable RNORMS.
      !  RVARI:    The location in array WORK of variable RVAR.
      !  SCLB:     The scaling values for BETA.
      !  SCLD:     The scaling values for DELTA.
      !  SDI:      The starting location in array WORK of array SD.
      !  SI:       The starting location in array WORK of array S.
      !  SSFI:     The starting location in array WORK of array SSF.
      !  SSI:      The starting location in array WORK of array SS.
      !  SSTOL:    The sum-of-squares convergence stopping tolerance.
      !  SSTOLI:   The location in array WORK of variable SSTOL.
      !  STPB:     The step size for finite difference derivatives wrt BETA.
      !  STPD:     The step size for finite difference derivatives wrt DELTA.
      !  TAUFAC:   The factor used to compute the initial trust region diameter.
      !  TAUFCI:   The location in array WORK of variable TAUFAC.
      !  TAUI:     The location in array WORK of variable TAU.
      !  TI:       The starting location in array WORK of array T.
      !  TSTIMP:   The relative change in the parameters between the initial values and
      !            the solution.
      !  TTI:      The starting location in array WORK of array TT.
      !  UI:       The starting location in array WORK of array U.
      !  UPPER:    The upper bound for BETA.
      !  VCVI:     The starting location in array WORK of array VCV.
      !  WD:       The DELTA weights.
      !  WE:       The EPSILON weights.
      !  WE1I:     The starting location in array WORK of array WE1.
      !  WORK:     The REAL (wp) work space.
      !  WRK:      The starting location in array WORK of array WRK, equivalenced to WRK1 and WRK2.
      !  WRK1I:    The starting location in array WORK of array WRK1.
      !  WRK2I:    The starting location in array WORK of array WRK2.
      !  WRK3I:    The starting location in array WORK of array WRK3.
      !  WRK4I:    The starting location in array WORK of array WRK4.
      !  WRK5I:    The starting location in array WORK of array WRK5.
      !  WRK6I:    The starting location in array WORK of array WRK6.
      !  WRK7I:    The starting location in array WORK of array WRK7.
      !  WSSI:     The location in array WORK of variable wss.
      !  WSSDEI:   The location in array WORK of variable WSSDEL.
      !  WSSEPI:   The location in array WORK of variable WSSEPS.
      !  X:        The explanatory variable.
      !  XPLUSI:   The starting location in array WORK of array XPLUSD.
      !  Y:        The dependent variable.  Unused when the model is implicit.

      ! Initialize necessary variables
      call dflags(job, restrt, initd, dovcv, redoj, anajac, cdjac, chkjac, isodr, implct)

      ! Set starting locations within integer workspace
      ! (invalid values of M, NP and/or NQ are handled reasonably by DIWINF)
      call diwinf(m, np, nq, &
                  msgb, msgd, jpvti, istopi, &
                  nnzwi, nppi, idfi, &
                  jobi, iprini, luneri, lunrpi, &
                  nrowi, ntoli, netai, &
                  maxiti, niteri, nfevi, njevi, int2i, iranki, ldtti, &
                  boundi, &
                  liwkmn)

      ! Set starting locations within REAL (wp) work space
      ! (invalid values of N, M, NP, NQ, LDWE and/or LD2WE
      ! are handled reasonably by DWINF)
      call dwinf(n, m, np, nq, ldwe, ld2we, isodr, &
                 deltai, fi, xplusi, fni, sdi, vcvi, &
                 rvari, wssi, wssdei, wssepi, rcondi, etai, &
                 olmavi, taui, alphai, actrsi, pnormi, rnorsi, prersi, &
                 partli, sstoli, taufci, epsmai, &
                 beta0i, betaci, betasi, betani, si, ssi, ssfi, qrauxi, ui, &
                 fsi, fjacbi, we1i, diffi, &
                 deltsi, deltni, ti, tti, omegai, fjacdi, &
                 wrk1i, wrk2i, wrk3i, wrk4i, wrk5i, wrk6i, wrk7i, &
                 loweri, upperi, &
                 lwkmn)

      if (isodr) then
         wrk = wrk1i
         lwrk = n*m*nq + n*nq
      else
         wrk = wrk2i
         lwrk = n*nq
      end if

      ! Update the penalty parameters
      ! (WE(1,1,1) is not a user supplied array in this case)
      if (restrt .and. implct) then
         we(1, 1, 1) = max(work(we1i)**2, abs(we(1, 1, 1)))
         work(we1i) = -sqrt(abs(we(1, 1, 1)))
      end if

      if (restrt) then

         ! Reset maximum number of iterations
         if (maxit >= 0) then
            iwork(maxiti) = iwork(niteri) + maxit
         else
            iwork(maxiti) = iwork(niteri) + 10
         end if

         if (iwork(niteri) < iwork(maxiti)) then
            info = 0
         end if

         if (job >= 0) iwork(jobi) = job
         if (iprint >= 0) iwork(iprini) = iprint
         if (partol >= zero .and. partol < one) work(partli) = partol
         if (sstol >= zero .and. sstol < one) work(sstoli) = sstol

         work(olmavi) = work(olmavi)*iwork(niteri)

         if (implct) then
            call dcopy(n*nq, work(fni), 1, work(fi), 1)
         else
            !call dxmy( n, nq, work( fni), n, y, ldy, work( fi), n)
            work(fi:fi + (n*nq - 1)) = &
               work(fni:fni + (n*nq - 1)) - reshape(y(1:n, :), shape=[n*nq])
         end if
         call dwght(n, nq, &
                    reshape(work(we1i:we1i + ldwe*ld2we*nq - 1), [ldwe, ld2we, nq]), &
                    ldwe, ld2we, &
                    reshape(work(fi:fi + n*nq - 1), [n, nq]), tempret(1:n, 1:nq))
         work(fi:fi + n*nq - 1) = reshape(tempret(1:n, 1:nq), [n*nq])
         work(wssepi) = ddot(n*nq, work(fi), 1, work(fi), 1)
         work(wssi) = work(wssepi) + work(wssdei)

      else

         ! Perform error checking
         info = 0
         call dodchk(n, m, np, nq, &
                     isodr, anajac, implct, &
                     beta, ifixb, &
                     ldx, ldifx, ldscld, ldstpd, ldwe, ld2we, ldwd, ld2wd, &
                     ldy, &
                     lwork, lwkmn, liwork, liwkmn, &
                     sclb, scld, stpb, stpd, &
                     info, &
                     lower, upper)
         if (info > 0) then
            goto 50
         end if

         ! Initialize work vectors as necessary
         do i = n*m + n*nq + 1, lwork
            work(i) = zero
         end do
         do i = 1, liwork
            iwork(i) = 0
         end do

         call diniwk(n, m, np, &
                     work, lwork, iwork, liwork, &
                     x, ldx, ifixx, ldifx, scld, ldscld, &
                     beta, sclb, &
                     sstol, partol, maxit, taufac, &
                     job, iprint, lunerr, lunrpt, &
                     lower, upper, &
                     epsmai, sstoli, partli, maxiti, taufci, &
                     jobi, iprini, luneri, lunrpi, &
                     ssfi, tti, ldtti, deltai, &
                     loweri, upperi, boundi)

         iwork(msgb) = -1
         iwork(msgd) = -1
         work(taui) = -work(taufci)

         ! Set up for parameter estimation -
         ! Pull BETA's to be estimated and corresponding scale values
         ! and store in WORK(BETACI) and WORK(SSI), respectively
         call dpack(np, iwork(nppi), work(betaci), beta, ifixb)
         call dpack(np, iwork(nppi), work(ssi), work(ssfi), ifixb)
         npp = iwork(nppi)

         ! Check that WD is positive definite and WE is positive semidefinite,
         ! saving factorization of WE, and counting number of nonzero weights
         call dfctrw(n, m, nq, npp, &
                     isodr, &
                     we, ldwe, ld2we, wd, ldwd, ld2wd, &
                     work(wrk2i), work(wrk4i), &
                     work(we1i), nnzw, info)
         iwork(nnzwi) = nnzw

         if (info /= 0) then
            goto 50
         end if

         ! Evaluate the predicted values and weighted EPSILONS at the starting point
         call dunpac(np, work(betaci), beta, ifixb)
         work(xplusi:xplusi + (n*m - 1)) = &
            work(deltai:deltai + (n*m - 1)) + reshape(x(1:n, :), shape=[n*m])
         istop = 0
         call fcn(n, m, np, nq, &
                  n, m, np, &
                  beta, work(xplusi), &
                  ifixb, ifixx, ldifx, &
                  002, work(fni), work(wrk6i), work(wrk1i), &
                  istop)
         iwork(istopi) = istop
         if (istop == 0) then
            iwork(nfevi) = iwork(nfevi) + 1
            if (implct) then
               call dcopy(n*nq, work(fni), 1, work(fi), 1)
            else
               !call dxmy( n, nq, work( fni), n, y, ldy, work( fi), n)
               work(fi:fi + (n*nq - 1)) = &
                  work(fni:fni + (n*nq - 1)) - reshape(y(1:n, :), shape=[n*nq])
            end if
            call dwght(n, nq, &
                       reshape(work(we1i:we1i + ldwe*ld2we*nq - 1), [ldwe, ld2we, nq]), &
                       ldwe, ld2we, &
                       reshape(work(fi:fi + n*nq - 1), [n, nq]), tempret(1:n, 1:nq))
            work(fi:fi + n*nq - 1) = reshape(tempret(1:n, 1:nq), [n*nq])
         else
            info = 52000
            goto 50
         end if

         ! Compute norm of the initial estimates
         call dwght(npp, 1, &
                    reshape(work(ssi:ssi + npp - 1), [npp, 1, 1]), &
                    npp, 1, &
                    reshape(work(betaci:betaci + npp - 1), [npp, 1]), tempret(1:npp, 1:1))
         work(wrk:wrk + npp - 1) = tempret(1:npp, 1)
         if (isodr) then
            call dwght(n, m, &
                       reshape(work(tti:tti + iwork(ldtti)*1*m - 1), [iwork(ldtti), 1, m]), &
                       iwork(ldtti), 1, &
                       reshape(work(deltai:deltai + n*m - 1), [n, m]), tempret(1:n, 1:m))
            work(wrk + npp:wrk + npp + n*m - 1) = reshape(tempret(1:n, 1:m), [n*m])
            work(pnormi) = dnrm2(npp + n*m, work(wrk), 1)
         else
            work(pnormi) = dnrm2(npp, work(wrk), 1)
         end if

         ! Compute sum of squares of the weighted EPSILONS and weighted DELTAS
         work(wssepi) = ddot(n*nq, work(fi), 1, work(fi), 1)
         if (isodr) then
            call dwght(n, m, wd, ldwd, ld2wd, &
                       reshape(work(deltai:deltai + n*m), [n, m]), &
                       tempret(1:n, 1:m))
            work(wrk:wrk + n*m - 1) = reshape(tempret(1:n, 1:m), [n*m])
            work(wssdei) = ddot(n*m, work(deltai), 1, work(wrk), 1)
         else
            work(wssdei) = zero
         end if
         work(wssi) = work(wssepi) + work(wssdei)

         ! Select first row of X + DELTA that contains no zeros
         nrow = -1
         call dsetn(n, m, work(xplusi), n, nrow)
         iwork(nrowi) = nrow

         ! Set number of good digits in function results
         epsmac = work(epsmai)
         if (ndigit < 2) then
            iwork(netai) = -1
            nfev = iwork(nfevi)
            call detaf(fcn, &
                       n, m, np, nq, &
                       work(xplusi), beta, epsmac, nrow, &
                       work(betani), work(fni), &
                       ifixb, ifixx, ldifx, &
                       istop, nfev, eta, neta, &
                       work(wrk1i), work(wrk2i), work(wrk6i), work(wrk7i), &
                       info, &
                       lower, upper)
            iwork(istopi) = istop
            iwork(nfevi) = nfev
            if (istop /= 0 .or. info /= 0) then
               if (info == 0) then
                  info = 53000
               end if
               iwork(netai) = 0
               work(etai) = zero
               goto 50
            else
               iwork(netai) = -neta
               work(etai) = eta
            end if
         else
            iwork(netai) = min(ndigit, int(p5 - log10(epsmac)))
            work(etai) = max(epsmac, ten**(-ndigit))
         end if

         ! Check bounds are large enough for derivative calculations.
         if (.not. anajac .or. chkjac) then
            if (cdjac) then
               do k = 1, np
                  if (upper(k) - abs(2*derstep(1, k, upper(k), work(ssfi), stpb, neta)) &
                      < lower(k)) then
                     info = 90020
                     goto 50
                  end if
               end do
            else
               do k = 1, np
                  if (upper(k) - abs(2*derstep(0, k, upper(k), work(ssfi), stpb, neta)) &
                      < lower(k)) then
                     info = 90020
                     goto 50
                  end if
               end do
            end if
         end if

         ! Check derivatives if necessary
         if (chkjac .and. anajac) then
            ntol = -1
            nfev = iwork(nfevi)
            njev = iwork(njevi)
            neta = iwork(netai)
            ldtt = iwork(ldtti)
            eta = work(etai)
            epsmac = work(epsmai)

            ! Ensure beta is not too close to bounds for the derivative check
            betaj(:) = beta(:)
            call mbfb(np, betaj, lower, upper, work(ssfi), stpb, neta, eta, interval)

            ! Check the derivatives
            call djck(fcn, &
                      n, m, np, nq, &
                      beta, betaj, work(xplusi), &
                      ifixb, ifixx, ldifx, stpb, stpd, ldstpd, &
                      work(ssfi), work(tti), ldtt, &
                      eta, neta, ntol, nrow, isodr, epsmac, &
                      work(fni), work(fjacbi), work(fjacdi), &
                      iwork(msgb), iwork(msgd), work(diffi), &
                      istop, nfev, njev, &
                      work(wrk1i), work(wrk2i), work(wrk6i), &
                      interval)
            iwork(istopi) = istop
            iwork(nfevi) = nfev
            iwork(njevi) = njev
            iwork(ntoli) = ntol
            if (istop /= 0) then
               info = 54000
            elseif (iwork(msgb) /= 0 .or. iwork(msgd) /= 0) then
               info = 40000
            end if
         else
            ! Indicate user supplied derivatives were not checked
            iwork(msgb) = -1
            iwork(msgd) = -1
         end if

         ! Print appropriate error messages
50       if ((info /= 0) .or. &
             (iwork(msgb) /= -1)) then
            if (lunerr /= 0 .and. iprint /= 0) then
               call dodper &
                  (info, lunerr, &
                   n, m, np, nq, &
                   ldscld, ldstpd, ldwe, ld2we, ldwd, ld2wd, &
                   lwkmn, liwkmn, &
                   work(fjacbi), work(fjacdi), &
                   work(diffi), iwork(msgb), isodr, iwork(msgd), &
                   work(xplusi), iwork(nrowi), iwork(netai), iwork(ntoli))
            end if

            ! Set INFO to reflect errors in the user supplied Jacobians
            if (info == 40000) then
               if (iwork(msgb) == 2 .or. iwork(msgd) == 2) then
                  if (iwork(msgb) == 2) then
                     info = info + 1000
                  end if
                  if (iwork(msgd) == 2) then
                     info = info + 100
                  end if
               else
                  info = 0
               end if
            end if
            if (info /= 0) then
               return
            end if
         end if
      end if

      ! Save the initial values of BETA
      call dcopy(np, beta, 1, work(beta0i), 1)

      ! Find least squares solution
      call dcopy(n*nq, work(fni), 1, work(fsi), 1)
      ldtt = iwork(ldtti)
      call dodmn(head, fstitr, prtpen, &
                 fcn, n, m, np, nq, job, beta, y, ldy, x, ldx, &
                 we, work(we1i), ldwe, ld2we, wd, ldwd, ld2wd, &
                 ifixb, ifixx, ldifx, &
                 work(betaci), work(betani), work(betasi), work(si), &
                 work(deltai), work(deltni), work(deltsi), &
                 work(loweri), work(upperi), &
                 work(ti), work(fi), work(fni), work(fsi), &
                 work(fjacbi), iwork(msgb), work(fjacdi), iwork(msgd), &
                 work(ssfi), work(ssi), work(tti), ldtt, &
                 stpb, stpd, ldstpd, &
                 work(xplusi), work(wrk), lwrk, &
                 work, lwork, tempret, iwork, liwork, info, &
                 iwork(boundi))
      maxit1 = iwork(maxiti) - iwork(niteri)
      tstimp = zero
      do k = 1, np
         if (beta(k) == zero) then
            tstimp = max(tstimp, abs(beta(k) - work(beta0i - 1 + k))/work(ssfi - 1 + k))
         else
            tstimp = max(tstimp, abs(beta(k) - work(beta0i - 1 + k))/abs(beta(k)))
         end if
      end do

   end subroutine doddrv

   impure subroutine dodmn &
      (head, fstitr, prtpen, &
       fcn, n, m, np, nq, job, beta, y, ldy, x, ldx, &
       we, we1, ldwe, ld2we, wd, ldwd, ld2wd, &
       ifixb, ifixx, ldifx, &
       betac, betan, betas, s, delta, deltan, deltas, &
       lower, upper, &
       t, f, fn, fs, fjacb, msgb, fjacd, msgd, &
       ssf, ss, tt, ldtt, stpb, stpd, ldstpd, &
       xplusd, wrk, lwrk, work, lwork, tempret, iwork, liwork, info, &
       bound)
   !! Iteratively compute least squares solution.
      ! Date Written   860529   (YYMMDD)
      ! Revision Date  920619   (YYMMDD)

      use odrpack_kinds, only: zero, one
      use odrpack_core, only: fcn_t, dacces, devjac, dflags, dunpac, dwght, dpack, dodvcv, &
                              dodlm

      logical, intent(in) :: head
         !! The variable designating whether the heading is to be printed (`head = .true.`)
         !! or not (`head = .false.`).
      logical, intent(inout) :: fstitr
         !! The variable designating whether this is the first iteration (`fstitr = .true.`)
         !! or not (`fstitr = .false.`).
      logical, intent(inout) :: prtpen
         !! The value designating whether the penalty parameter is to be printed in the
         !! iteration report (`prtpen = .true.`) or not (`prtpen = .false.`).
      procedure(fcn_t) :: fcn
         !! The user supplied subroutine for evaluating the model.
      integer, intent(in) :: n
         !! The number of observations.
      integer, intent(in) :: m
         !! The number of columns of data in the explanatory variable.
      integer, intent(in) :: np
         !! The number of function parameters.
      integer, intent(in) :: nq
         !! The number of responses per observation.
      integer, intent(inout) :: job
         !! The variable controlling problem initialization and computational method.
      real(wp), intent(inout) :: beta(np)
         !! The function parameters.
      real(wp), intent(in) :: y(ldy, nq)
         !! The dependent variable. Unused when the model is implicit.
      integer, intent(in) :: ldy
         !! The leading dimension of array `y`.
      real(wp), intent(in) :: x(ldx, m)
         !! The explanatory variable.
      integer, intent(in) :: ldx
         !! The leading dimension of array `x`.
      real(wp), intent(in) :: we(ldwe, ld2we, nq)
         !! The `epsilon` weights.
      real(wp), intent(in) :: we1(ldwe, ld2we, nq)
         !! The square root of the `epsilon` weights.
      integer, intent(in) :: ldwe
         !! The leading dimension of arrays `we` and `we1`.
      integer, intent(in) :: ld2we
         !! The second dimension of arrays `we` and `we1`.
      real(wp), intent(in) :: wd(ldwd, ld2wd, m)
         !! The `delta` weights.
      integer, intent(in) :: ldwd
         !! The leading dimension of array `wd`.
      integer, intent(in) :: ld2wd
         !! The second dimension of array `wd`.
      integer, intent(in) :: ifixb(np)
         !! The values designating whether the elements of `beta` are fixed at their input
         !! values or not.
      integer, intent(in) :: ifixx(ldifx, m)
         !! The values designating whether the elements of `x` are fixed at their input
         !! values or not.
      integer, intent(in) :: ldifx
         !! The leading dimension of array `ifixx`.
      real(wp), intent(inout) :: betac(np)
         !! The current estimated values of the unfixed `beta`s.
      real(wp), intent(out) :: betan(np)
         !! The new estimated values of the unfixed `beta`s.
      real(wp), intent(in) :: betas(np)
         !! The saved estimated values of the unfixed `beta`s.
      real(wp), intent(out) :: s(np)
         !! The step for `beta`.
      real(wp), intent(in) :: delta(n, m)
         !! The estimated errors in the explanatory variables.
      real(wp), intent(out) :: deltan(n, m)
         !! The new estimated errors in the explanatory variables.
      real(wp), intent(inout) :: deltas(n, m)
         !! The saved estimated errors in the explanatory variables.
      real(wp), intent(in) :: lower(np)
         !! The lower bound for unfixed `beta`s.
      real(wp), intent(in) :: upper(np)
         !! The upper bound for unfixed `beta`s.
      real(wp), intent(out) :: t(n, m)
         !! The step for `delta`.
      real(wp), intent(inout) :: f(n, nq)
         !! The (weighted) estimated values of `epsilon`.
      real(wp), intent(out) :: fn(n, nq)
         !! The new predicted values from the function.
      real(wp), intent(out) :: fs(n, nq)
         !! The saved predicted values from the function.
      real(wp), intent(out) :: fjacb(n, np, nq)
         !! The Jacobian with respect to `beta`.
      integer, intent(in) :: msgb(nq*np + 1)
         !! The error checking results for the Jacobian with respect to `beta`.
      real(wp), intent(out) :: fjacd(n, m, nq)
         !! The Jacobian with respect to `delta`.
      integer, intent(in) :: msgd(nq*m + 1)
         !! The error checking results for the Jacobian with respect to `delta`.
      real(wp), intent(in) :: ssf(np)
         !! The scaling values used for `beta`.
      real(wp), intent(in) :: ss(np)
         !! The scaling values used for the unfixed `beta`s.
      real(wp), intent(in) :: tt(ldtt, m)
         !! The scaling values used for `delta`.
      integer, intent(in) :: ldtt
         !! The leading dimension of array `tt`.
      real(wp), intent(in) :: stpb(np)
         !! The relative step used for computing finite difference derivatives with respect
         !! to each `beta`.
      real(wp), intent(in) :: stpd(ldstpd, m)
         !! The relative step used for computing finite difference derivatives with respect
         !! to `delta`.
      integer, intent(in) :: ldstpd
         !! The leading dimension of array `stpd`.
      real(wp), intent(out) :: xplusd(n, m)
         !! The values of `x + delta`.
      real(wp), intent(inout) :: wrk(lwrk)
         !! A work array, _equivalenced_ to `wrk1` and `wrk2`.
      integer, intent(in) :: lwrk
         !! The length of vector `wrk`.
      real(wp), intent(inout) :: work(lwork)
         !! The real (wp) workspace.
      integer, intent(in) :: lwork
         !! The length of vector `work`.
      real(wp), intent(inout) :: tempret(:, :)
         !! Temporary work array for holding return values before copying to a lower rank array.
      integer, intent(inout) :: iwork(liwork)
         !! The integer workspace.
      integer, intent(in) :: liwork
         !! The length of vector `iwork`.
      integer, intent(inout) :: info
         !! The variable designating why the computations were stopped.
      integer, intent(out) :: bound(np)
         !! The values of the bounds for `beta`.

      ! Local scalars
      real(wp), parameter :: p0001 = 0.00010_wp, &
                             p1 = 0.1_wp, &
                             p25 = 0.25_wp, &
                             p5 = 0.5_wp, &
                             p75 = 0.75_wp
      real(wp) :: actred, actrs, alpha, dirder, eta, olmavg, partol, pnorm, prered, &
                  prers, ratio, rcond, rnorm, rnormn, rnorms, rss, rvar, sstol, tau, &
                  taufac, temp, temp1, temp2, tsnorm

      integer, parameter :: ludflt = 6
      integer :: i, idf, iflag, int2, ipr, ipr1, ipr2, ipr2f, ipr3, irank, istop, istopc, &
                 iwrk, j, jpvt, l, looped, lunr, lunrpt, maxit, neta, nfev, niter, njev, &
                 nlms, nnzw, npp, npr, npu, omega, qraux, sd, u, vcv, wrk1, wrk2, wrk3, &
                 wrk4, wrk5, wrk6
      logical :: access, anajac, cdjac, chkjac, cnvpar, cnvss, didvcv, dovcv, implct, initd, &
                 intdbl, isodr, lstep, redoj, restrt

      ! Local arrays
      real(wp) :: loweru(np), upperu(np), wss(3)

      ! External BLAS/LAPACK procedures
      real(wp), external :: ddot, dnrm2
      external :: dcopy

      ! External ODRPACK procedures
      ! @todo: place in module
      external :: dodpcr

      ! Variable Definitions (alphabetically)
      !  ACCESS:  The variable designating whether information is to be accessed from the work
      !           arrays (ACCESS=TRUE) or stored in them (ACCESS=FALSE).
      !  ACTRED:  The actual relative reduction in the sum-of-squares.
      !  ACTRS:   The saved actual relative reduction in the sum-of-squares.
      !  ALPHA:   The Levenberg-Marquardt parameter.
      !  ANAJAC:  The variable designating whether the Jacobians are computed by finite
      !           differences (ANAJAC=FALSE) or not (ANAJAC=TRUE).
      !  BETA:    The function parameters.
      !  BETAC:   The current estimated values of the unfixed BETA'S.
      !  BETAN:   The new estimated values of the unfixed BETA'S.
      !  BETAS:   The saved estimated values of the unfixed BETA'S.
      !  CDJAC:   The variable designating whether the Jacobians are computed by central
      !           differences (cdjac=true) or by forward differences (CDJAC=FALSE).
      !  CHKJAC:  The variable designating whether the user supplied Jacobians are to be
      !           checked (CHKJAC=TRUE) or not (CHKJAC=FALSE).
      !  CNVPAR:  The variable designating whether parameter convergence was attained
      !           (CNVPAR=TRUE) or not (CNVPAR=FALSE).
      !  CNVSS:   The variable designating whether sum-of-squares convergence was attained
      !           (CNVSS=TRUE) or not (CNVSS=FALSE).
      !  DELTA:   The estimated errors in the explanatory variables.
      !  DELTAN:  The new estimated errors in the explanatory variables.
      !  DELTAS:  The saved estimated errors in the explanatory variables.
      !  DIDVCV:  The variable designating whether the covariance matrix was computed
      !           (DIDVCV=TRUE) or not (DIDVCV=FALSE).
      !  DIRDER:  The directional derivative.
      !  DOVCV:   The variable designating whether the covariance matrix should to be
      !           computed (DOVCV=TRUE) or not (DOVCV=FALSE).
      !  ETA:     The relative noise in the function results.
      !  F:       The (weighted) estimated values of EPSILON.
      !  FCN:     The user supplied subroutine for evaluating the model.
      !  FJACB:   The Jacobian with respect to BETA.
      !  FJACD:   The Jacobian with respect to DELTA.
      !  FN:      The new predicted values from the function.
      !  FS:      The saved predicted values from the function.
      !  FSTITR:  The variable designating whether this is the first iteration (FSTITR=TRUE)
      !           or not (FSTITR=FALSE).
      !  HEAD:    The variable designating whether the heading is to be printed (HEAD=TRUE) or
      !           not (HEAD=FALSE).
      !  I:       An indexing variable.
      !  IDF:     The degrees of freedom of the fit, equal to the number of observations with
      !           nonzero weighted derivatives minus the number of parameters being estimated.
      !  IFIXB:   The values designating whether the elements of BETA are fixed at their input
      !           values or not.
      !  IFIXX:   The values designating whether the elements of X are fixed at their input
      !           values or not.
      !  IFLAG:   The variable designating which report is to be printed.
      !  IMPLCT:  The variable designating whether the solution is by implicit ODR (IMPLCT=TRUE)
      !           or explicit ODR (IMPLCT=FALSE).
      !  INFO:    The variable designating why the computations were stopped.
      !  INITD:   The variable designating whether delta is initialized to zero (INITD=TRUE) or
      !           to the values in the first N by M elements of array work (INITD=FALSE).
      !  INT2:    The number of internal doubling steps taken.
      !  INTDBL:  The variable designating whether internal doubling is to be used (INTDBL=TRUE)
      !           or NOT (INTDBL=FALSE).
      !  IPR:     The values designating the length of the printed report.
      !  IPR1:    The value of the 4th digit (from the right) of iprint, which controls the
      !           initial summary report.
      !  IPR2:    The value of the 3rd digit (from the right) of iprint, which controls the
      !           final iteration report.
      !  IPR2F:   The value of the 2nd digit (from the right) of iprint, which controls the
      !           frequency of the iteration reports.
      !  IPR3:    The value of the 1st digit (from the right) of iprint, which controls the final
      !           summary report.
      !  IRANK:   The rank deficiency of the Jacobian wrt BETA.
      !  ISODR:   The variable designating whether the solution is by ODR (ISODR=TRUE) or
      !           OLS (ISODR=FALSE).
      !  ISTOP:   The variable designating whether there are problems computing the function
      !           at the current BETA and DELTA.
      !  ISTOPC:  The variable designating whether the computations were stoped due to some
      !           numerical error within routine  DODSTP.
      !  IWORK:   The integer work space.
      !  IWRK:    An index variable.
      !  J:       An index variable.
      !  JOB:     The variable controling problem initialization and computational method.
      !  JPVT:    The starting location in IWORK of array JPVT.
      !  L:       An index variable.
      !  LDIFX:   The leading dimension of array IFIXX.
      !  LDTT:    The leading dimension of array TT.
      !  LDWD:    The leading dimension of array WD.
      !  LDWE:    The leading dimension of array WE and WE1.
      !  LDX:     The leading dimension of array X.
      !  LDY:     The leading dimension of array Y.
      !  LD2WD:   The second dimension of array WD.
      !  LD2WE:   The second dimension of array WE and WE1.
      !  LIWORK:  The length of vector IWORK.
      !  LOOPED:  A counter used to determine how many times the subloop has been executed,
      !           where if the count becomes large enough the computations will be stopped.
      !  LOWERU:  The lower bound for unfixed BETAs.
      !  LSTEP:   The variable designating whether a successful step has been found (LSTEP=TRUE)
      !           or not (LSTEP=FALSE).
      !  LUDFLT:  The default logical unit number, used for computation reports to the screen.
      !  LUNR:    The logical unit number used for computation reports.
      !  LUNRPT:  The logical unit number used for computation reports.
      !  LWORK:   The length of vector WORK.
      !  LWRK:    The length of vector WRK.
      !  M:       The number of columns of data in the explanatory variable.
      !  MAXIT:   The maximum number of iterations allowed.
      !  MSGB:    The error checking results for the Jacobian wrt BETA.
      !  MSGD:    The error checking results for the Jacobian wrt DELTA.
      !  N:       The number of observations.
      !  NETA:    The number of accurate digits in the function results.
      !  NFEV:    The number of function evaluations.
      !  NITER:   The number of iterations taken.
      !  NJEV:    The number of Jacobian evaluations.
      !  NLMS:    The number of Levenberg-Marquardt steps taken.
      !  NNZW:    The number of nonzero weighted observations.
      !  NP:      The number of function parameters.
      !  NPP:     The number of function parameters being estimated.
      !  NPR:     The number of times the report is to be written.
      !  NPU:     The number of unfixed parameters.
      !  NQ:      The number of responses per observation.
      !  OLMAVG:  The average number of Levenberg-Marquardt steps per iteration.
      !  OMEGA:   The starting location in WORK of array OMEGA.
      !  PARTOL:  The parameter convergence stopping tolerance.
      !  PNORM:   The norm of the scaled estimated parameters.
      !  PRERED:  The predicted relative reduction in the sum-of-squares.
      !  PRERS:   The old predicted relative reduction in the sum-of-squares.
      !  PRTPEN:  The value designating whether the penalty parameter is to be printed in the
      !           iteration report (PRTPEN=TRUE) or not (PRTPEN=FALSE).
      !  QRAUX:   The starting location in array WORK of array QRAUX.
      !  RATIO:   The ratio of the actual relative reduction to the predicted relative reduction
      !           in the sum-of-squares.
      !  RCOND:   The approximate reciprocal condition of FJACB.
      !  REDOJ:   The variable designating whether the Jacobian matrix is to be recomputed for
      !           the computation of the covariance matrix (REDOJ=TRUE) or not (REDOJ=FALSE).
      !  RESTRT:  The variable designating whether the call is a restart (RESTRT=TRUE) or
      !           not (RESTRT=FALSE).
      !  RNORM:   The norm of the weighted errors.
      !  RNORMN:  The new norm of the weighted errors.
      !  RNORMS:  The saved norm of the weighted errors.
      !  RSS:     The residual sum of squares.
      !  RVAR:    The residual variance.
      !  S:       The step for BETA.
      !  SD:      The starting location in array work of array SD.
      !  SS:      The scaling values used for the unfixed BETAS.
      !  SSF:     The scaling values used for BETA.
      !  SSTOL:   The sum-of-squares convergence stopping tolerance.
      !  STPB:    The relative step used for computing finite difference derivatives with
      !           respect to each BETA.
      !  STPD:    The relative step used for computing finite difference derivatives with respect
      !           to DELTA.
      !  T:       The step for DELTA.
      !  TAU:     The trust region diameter.
      !  TAUFAC:  The factor used to compute the initial trust region diameter.
      !  TEMP:    A temporary storage location.
      !  TEMP1:   A temporary storage location.
      !  TEMP2:   A temporary storage location.
      !  TSNORM:  The norm of the scaled step.
      !  TT:      The scaling values used for DELTA.
      !  U:       The starting location in array WORK of array U.
      !  UPPERU:  The upper bound for unfixed BETAs.
      !  VCV:     The starting location in array WORK of array VCV.
      !  WE:      The EPSILON weights.
      !  WE1:     The square root of the EPSILON weights.
      !  WD:      The DELTA weights.
      !  WORK:    The REAL (wp) work space.
      !  WSS:     The sum-of-squares of the weighted EPSILONS and DELTAS, the sum-of-squares
      !           of the weighted DELTAS, and the sum-of-squares of the weighted EPSILONS.
      !  WRK:     A work array, equivalenced to WRK1 and WRK2
      !  WRK1:    The starting location in array WORK of array WRK1.
      !  WRK2:    The starting location in array WORK of array WRK2.
      !  WRK3:    The starting location in array WORK of array WRK3.
      !  WRK4:    The starting location in array WORK of array WRK4.
      !  WRK5:    The starting location in array WORK of array WRK5.
      !  WRK6:    The starting location in array WORK of array WRK6.
      !  X:       The explanatory variable.
      !  XPLUSD:  The values of X + DELTA.
      !  Y:       The dependent variable. Unused when the model is implicit.

      ! Initialize necessary variables
      call dpack(np, npu, loweru, lower, ifixb)
      call dpack(np, npu, upperu, upper, ifixb)
      call dflags(job, restrt, initd, dovcv, redoj, &
                  anajac, cdjac, chkjac, isodr, implct)
      access = .true.
      call dacces(n, m, np, nq, ldwe, ld2we, &
                  work, lwork, iwork, liwork, &
                  access, isodr, &
                  jpvt, omega, u, qraux, sd, vcv, &
                  wrk1, wrk2, wrk3, wrk4, wrk5, wrk6, &
                  nnzw, npp, &
                  job, partol, sstol, maxit, taufac, eta, neta, &
                  lunrpt, ipr1, ipr2, ipr2f, ipr3, &
                  wss, rvar, idf, &
                  tau, alpha, niter, nfev, njev, int2, olmavg, &
                  rcond, irank, actrs, pnorm, prers, rnorms, istop)
      rnorm = sqrt(wss(1))

      didvcv = .false.
      intdbl = .false.
      lstep = .true.

      ! Print initial summary if desired
      if (ipr1 /= 0 .and. lunrpt /= 0) then
         iflag = 1
         if (ipr1 >= 3 .and. lunrpt /= ludflt) then
            npr = 2
         else
            npr = 1
         end if
         if (ipr1 >= 6) then
            ipr = 2
         else
            ipr = 2 - mod(ipr1, 2)
         end if
         lunr = lunrpt
         do i = 1, npr
            call dodpcr(ipr, lunr, &
                        head, prtpen, fstitr, didvcv, iflag, &
                        n, m, np, nq, npp, nnzw, &
                        msgb, msgd, beta, y, ldy, x, ldx, delta, &
                        we, ldwe, ld2we, wd, ldwd, ld2wd, &
                        ifixb, ifixx, ldifx, &
                        lower, upper, &
                        ssf, tt, ldtt, stpb, stpd, ldstpd, &
                        job, neta, taufac, sstol, partol, maxit, &
                        wss, rvar, idf, work(sd), &
                        niter, nfev, njev, actred, prered, &
                        tau, pnorm, alpha, f, rcond, irank, info, istop)
            if (ipr1 >= 5) then
               ipr = 2
            else
               ipr = 1
            end if
            lunr = ludflt
         end do
      end if

      ! Stop if initial estimates are exact solution
      if (rnorm == zero) then
         info = 1
         olmavg = zero
         istop = 0
         goto 150
      end if

      ! Stop if number of iterations already equals maximum permitted
      if (restrt .and. &
          (niter >= maxit)) then
         istop = 0
         goto 150
      elseif (niter >= maxit) then
         info = 4
         istop = 0
         goto 150
      end if

      ! MAIN LOOP
100   continue

      niter = niter + 1
      rnorms = rnorm
      looped = 0

      ! Evaluate jacobian using best estimate of function (FS)
      if ((niter == 1) .and. &
          (anajac .and. chkjac)) then
         istop = 0
      else
         call devjac(fcn, &
                     anajac, cdjac, &
                     n, m, np, nq, &
                     betac, beta, stpb, &
                     ifixb, ifixx, ldifx, &
                     x, ldx, delta, xplusd, stpd, ldstpd, &
                     ssf, tt, ldtt, neta, fs, &
                     t, work(wrk1), work(wrk2), work(wrk3), work(wrk6), tempret, &
                     fjacb, isodr, fjacd, we1, ldwe, ld2we, &
                     njev, nfev, istop, info, &
                     lower, upper)
      end if
      if (istop /= 0) then
         info = 51000
         goto 200
      elseif (info == 50300) then
         goto 200
      end if

      ! SUB-LOOP for internal doubling or computing new step when old failed
110   continue

      ! Compute steps S and T
      if (looped > 100) then
         info = 60000
         goto 200
      else
         looped = looped + 1
         call dodlm(n, m, np, nq, npp, &
                    f, fjacb, fjacd, &
                    wd, ldwd, ld2wd, ss, tt, ldtt, delta, &
                    alpha, tau, eta, isodr, &
                    work(wrk6), work(omega), &
                    work(u), work(qraux), iwork(jpvt), &
                    s, t, nlms, rcond, irank, &
                    work(wrk1), work(wrk2), work(wrk3), work(wrk4), &
                    work(wrk5), wrk, lwrk, tempret, istopc)
      end if
      if (istopc /= 0) then
         info = istopc
         goto 200
      end if
      olmavg = olmavg + nlms

      ! Compute BETAN = BETAC + S
      !         DELTAN = DELTA + T
      betan = betac + s
      if (isodr) deltan = delta + t

      ! Project the step wrt the bounds
      do i = 1, npu
         if (loweru(i) == upperu(i)) then
            betan(i) = upperu(i)
            s(i) = upperu(i) - betac(i)
            bound(i) = 3
         elseif (betan(i) <= loweru(i)) then
            betan(i) = loweru(i)
            s(i) = loweru(i) - betac(i)
            bound(i) = 2
         elseif (betan(i) >= upperu(i)) then
            betan(i) = upperu(i)
            s(i) = upperu(i) - betac(i)
            bound(i) = 1
         else
            bound(i) = 0
         end if
      end do

      ! Compute norm of scaled steps S and T (TSNORM)
      call dwght(npp, 1, reshape(ss, [npp, 1, 1]), npp, 1, &
                 reshape(s, [npp, 1]), tempret(1:npp, 1:1))
      wrk(1:npp) = tempret(1:npp, 1)
      if (isodr) then
         call dwght(n, m, reshape(tt, [ldtt, 1, m]), ldtt, 1, t, tempret(1:n, 1:m))
         wrk(npp + 1:npp + 1 + n*m - 1) = reshape(tempret(1:n, 1:m), [n*m])
         tsnorm = dnrm2(npp + n*m, wrk, 1)
      else
         tsnorm = dnrm2(npp, wrk, 1)
      end if

      ! Compute scaled predicted reduction
      iwrk = 0
      do l = 1, nq
         do i = 1, n
            iwrk = iwrk + 1
            wrk(iwrk) = ddot(npp, fjacb(i, 1, l), n, s, 1)
            if (isodr) wrk(iwrk) = wrk(iwrk) + ddot(m, fjacd(i, 1, l), n, t(i, 1), n)
         end do
      end do
      if (isodr) then
         call dwght(n, m, wd, ldwd, ld2wd, t, tempret(1:n, 1:m))
         wrk(n*nq + 1:n*nq + 1 + n*m - 1) = reshape(tempret(1:n, 1:m), [n*m])
         temp1 = ddot(n*nq, wrk, 1, wrk, 1) + ddot(n*m, t, 1, wrk(n*nq + 1), 1)
         temp1 = sqrt(temp1)/rnorm
      else
         temp1 = dnrm2(n*nq, wrk, 1)/rnorm
      end if
      temp2 = sqrt(alpha)*tsnorm/rnorm
      prered = temp1**2 + temp2**2/p5

      dirder = -(temp1**2 + temp2**2)

      ! Evaluate predicted values at new point
      call dunpac(np, betan, beta, ifixb)
      xplusd = x(1:n, :) + deltan
      istop = 0
      call fcn(n, m, np, nq, &
               n, m, np, &
               beta, xplusd, &
               ifixb, ifixx, ldifx, &
               002, fn, work(wrk6), work(wrk1), &
               istop)
      if (istop == 0) then
         nfev = nfev + 1
      end if

      if (istop < 0) then
         ! Set INFO to indicate user has stopped the computations in FCN
         info = 51000
         goto 200
      elseif (istop > 0) then
         ! Set norm to indicate step should be rejected
         rnormn = rnorm/(p1*p75)
      else
         ! Compute norm of new weighted EPSILONS and weighted DELTAS (RNORMN)
         if (implct) then
            call dcopy(n*nq, fn, 1, wrk, 1)
         else
            !call dxmy( n, nq, fn, n, y, ldy, wrk, n)
            wrk(1:n*nq) = reshape(fn - y(1:n, :), [n*nq])
         end if
         call dwght(n, nq, we1, ldwe, ld2we, reshape(wrk, [n, nq]), &
                    tempret(1:n, 1:nq))
         wrk(1:n*nq) = reshape(tempret(1:n, 1:nq), [n*nq])
         if (isodr) then
            call dwght(n, m, wd, ldwd, ld2wd, deltan, tempret(1:n, 1:m))
            wrk(n*nq + 1:n*nq + 1 + n*m - 1) = reshape(tempret(1:n, 1:m), [n*m])
            rnormn = sqrt(ddot(n*nq, wrk, 1, wrk, 1) + &
                          ddot(n*m, deltan, 1, wrk(n*nq + 1), 1))
         else
            rnormn = dnrm2(n*nq, wrk, 1)
         end if
      end if

      ! Compute scaled actual reduction
      if (p1*rnormn < rnorm) then
         actred = one - (rnormn/rnorm)**2
      else
         actred = -one
      end if

      ! Compute ratio of actual reduction to predicted reduction
      if (prered == zero) then
         ratio = zero
      else
         ratio = actred/prered
      end if

      ! Check on lack of reduction in internal doubling case
      if (intdbl .and. (ratio < p0001 .or. rnormn > rnorms)) then
         istop = 0
         tau = tau*p5
         alpha = alpha/p5
         call dcopy(npp, betas, 1, betan, 1)
         call dcopy(n*m, deltas, 1, deltan, 1)
         call dcopy(n*nq, fs, 1, fn, 1)
         actred = actrs
         prered = prers
         rnormn = rnorms
         ratio = p5
      end if

      ! Update step bound
      intdbl = .false.
      if (ratio < p25) then
         if (actred >= zero) then
            temp = p5
         else
            temp = p5*dirder/(dirder + p5*actred)
         end if
         if (p1*rnormn >= rnorm .or. temp < p1) then
            temp = p1
         end if
         tau = temp*min(tau, tsnorm/p1)
         alpha = alpha/temp
      elseif (alpha == zero) then
         tau = tsnorm/p5

      elseif (ratio >= p75 .and. nlms <= 11) then
         ! Step qualifies for internal doubling
         !  - Update TAU and ALPHA
         !  - Save information for current point

         intdbl = .true.

         tau = tsnorm/p5
         alpha = alpha*p5

         call dcopy(npp, betan, 1, betas, 1)
         call dcopy(n*m, deltan, 1, deltas, 1)
         call dcopy(n*nq, fn, 1, fs, 1)
         actrs = actred
         prers = prered
         rnorms = rnormn
      end if

      ! If internal doubling, skip convergence checks
      if (intdbl .and. tau > zero) then
         int2 = int2 + 1
         goto 110
      end if

      ! Check acceptance
      if (ratio >= p0001) then
         call dcopy(n*nq, fn, 1, fs, 1)
         if (implct) then
            call dcopy(n*nq, fs, 1, f, 1)
         else
            !call dxmy( n, nq, fs, n, y, ldy, f, n)
            f = fs - y(1:n, :)
         end if
         call dwght(n, nq, we1, ldwe, ld2we, f, tempret(1:n, 1:nq))
         f(1:n, 1:nq) = tempret(1:n, 1:nq)
         call dcopy(npp, betan, 1, betac, 1)
         call dcopy(n*m, deltan, 1, delta, 1)
         rnorm = rnormn
         call dwght(npp, 1, reshape(ss, [npp, 1, 1]), npp, 1, &
                    reshape(betac, [npp, 1]), tempret(1:npp, 1:1))
         wrk(1:npp) = tempret(1:npp, 1)
         if (isodr) then
            call dwght(n, m, reshape(tt, [ldtt, 1, m]), ldtt, 1, delta, tempret(1:n, 1:m))
            wrk(npp + 1:npp + 1 + n*m - 1) = reshape(tempret(1:n, 1:m), [n*m])
            pnorm = dnrm2(npp + n*m, wrk, 1)
         else
            pnorm = dnrm2(npp, wrk, 1)
         end if
         lstep = .true.
      else
         lstep = .false.
      end if

      ! Test convergence
      info = 0
      cnvss = rnorm == zero &
              .or. &
              (abs(actred) <= sstol .and. &
               prered <= sstol .and. &
               p5*ratio <= one)
      cnvpar = (tau <= partol*pnorm) .and. (.not. implct)
      if (cnvss) info = 1
      if (cnvpar) info = 2
      if (cnvss .and. cnvpar) info = 3

      ! Print iteration report
      if (info /= 0 .or. lstep) then
         if (ipr2 /= 0 .and. ipr2f /= 0 .and. lunrpt /= 0) then
            if (ipr2f == 1 .or. mod(niter, ipr2f) == 1) then
               iflag = 2
               call dunpac(np, betac, beta, ifixb)
               wss(1) = rnorm*rnorm
               if (ipr2 >= 3 .and. lunrpt /= ludflt) then
                  npr = 2
               else
                  npr = 1
               end if
               if (ipr2 >= 6) then
                  ipr = 2
               else
                  ipr = 2 - mod(ipr2, 2)
               end if
               lunr = lunrpt
               do i = 1, npr
                  call dodpcr(ipr, lunr, &
                              head, prtpen, fstitr, didvcv, iflag, &
                              n, m, np, nq, npp, nnzw, &
                              msgb, msgd, beta, y, ldy, x, ldx, delta, &
                              we, ldwe, ld2we, wd, ldwd, ld2wd, &
                              ifixb, ifixx, ldifx, &
                              lower, upper, &
                              ssf, tt, ldtt, stpb, stpd, ldstpd, &
                              job, neta, taufac, sstol, partol, maxit, &
                              wss, rvar, idf, work(sd), &
                              niter, nfev, njev, actred, prered, &
                              tau, pnorm, alpha, f, rcond, irank, info, istop)
                  if (ipr2 >= 5) then
                     ipr = 2
                  else
                     ipr = 1
                  end if
                  lunr = ludflt
               end do
               fstitr = .false.
               prtpen = .false.
            end if
         end if
      end if

      ! Check if finished
      if (info == 0) then

         if (lstep) then
            ! Begin next interation unless a stopping criteria has been met
            if (niter >= maxit) then
               info = 4
            else
               goto 100
            end if
         else
            ! Step failed - recompute unless a stopping criteria has been met
            goto 110
         end if

      end if

150   continue

      if (istop > 0) info = info + 100

      ! Store unweighted EPSILONS and X+DELTA to return to user
      if (implct) then
         call dcopy(n*nq, fs, 1, f, 1)
      else
         !call dxmy( n, nq, fs, n, y, ldy, f, n)
         f = fs - y(1:n, :)
      end if
      call dunpac(np, betac, beta, ifixb)
      xplusd = x(1:n, :) + delta

      ! Compute covariance matrix of estimated parameters in upper NP by NP portion
      ! of WORK(VCV) if requested
      if (dovcv .and. istop == 0) then

         ! Re-evaluate Jacobian at final solution, if requested
         ! Otherwise, Jacobian from beginning of last iteration will be used
         ! to compute covariance matrix
         if (redoj) then
            call devjac(fcn, &
                        anajac, cdjac, &
                        n, m, np, nq, &
                        betac, beta, stpb, &
                        ifixb, ifixx, ldifx, &
                        x, ldx, delta, xplusd, stpd, ldstpd, &
                        ssf, tt, ldtt, neta, fs, &
                        t, work(wrk1), work(wrk2), work(wrk3), work(wrk6), tempret, &
                        fjacb, isodr, fjacd, we1, ldwe, ld2we, &
                        njev, nfev, istop, info, &
                        lower, upper)

            if (istop /= 0) then
               info = 51000
               goto 200
            elseif (info == 50300) then
               goto 200
            end if
         end if

         if (implct) then
            call dwght(n, m, wd, ldwd, ld2wd, delta, tempret(1:n, 1:m))
            wrk(n*nq + 1:n*nq + 1 + n*m - 1) = reshape(tempret(1:n, 1:m), [n*m])
            rss = ddot(n*m, delta, 1, wrk(n*nq + 1), 1)
         else
            rss = rnorm*rnorm
         end if
         if (redoj .or. niter >= 1) then
            call dodvcv(n, m, np, nq, npp, &
                        f, fjacb, fjacd, &
                        wd, ldwd, ld2wd, ssf, ss, tt, ldtt, delta, &
                        eta, isodr, &
                        work(vcv), work(sd), &
                        work(wrk6), work(omega), &
                        work(u), work(qraux), iwork(jpvt), &
                        s, t, irank, rcond, rss, idf, rvar, ifixb, &
                        work(wrk1), work(wrk2), work(wrk3), work(wrk4), &
                        work(wrk5), wrk, lwrk, tempret, istopc)
            if (istopc /= 0) then
               info = istopc
               goto 200
            end if
            didvcv = .true.
         end if

      end if

      ! Set JPVT to indicate dropped, fixed and estimated parameters
200   do i = 0, np - 1
         work(wrk3 + i) = iwork(jpvt + i)
         iwork(jpvt + i) = -2
      end do
      if (redoj .or. niter >= 1) then
         do i = 0, npp - 1
            j = int(work(wrk3 + i)) - 1
            if (i <= npp - irank - 1) then
               iwork(jpvt + j) = 1
            else
               iwork(jpvt + j) = -1
            end if
         end do
         if (npp < np) then
            j = npp - 1
            do i = np - 1, 0, -1
               if (ifixb(i + 1) == 0) then
                  iwork(jpvt + i) = 0
               else
                  iwork(jpvt + i) = iwork(jpvt + j)
                  j = j - 1
               end if
            end do
         end if
      end if

      ! Store various scalars in work arrays for return to user
      if (niter >= 1) then
         olmavg = olmavg/niter
      else
         olmavg = zero
      end if

      ! Compute weighted sums of squares for return to user
      call dwght(n, nq, we1, ldwe, ld2we, f, tempret(1:n, 1:nq))
      wrk(1:n*nq) = reshape(tempret(1:n, 1:nq), [n*nq])
      wss(3) = ddot(n*nq, wrk, 1, wrk, 1)
      if (isodr) then
         call dwght(n, m, wd, ldwd, ld2wd, delta, tempret(1:n, 1:m))
         wrk(n*nq + 1:n*nq + 1 + n*m - 1) = reshape(tempret(1:n, 1:m), [n*m])
         wss(2) = ddot(n*m, delta, 1, wrk(n*nq + 1), 1)
      else
         wss(2) = zero
      end if
      wss(1) = wss(2) + wss(3)

      access = .false.
      call dacces(n, m, np, nq, ldwe, ld2we, &
                  work, lwork, iwork, liwork, &
                  access, isodr, &
                  jpvt, omega, u, qraux, sd, vcv, &
                  wrk1, wrk2, wrk3, wrk4, wrk5, wrk6, &
                  nnzw, npp, &
                  job, partol, sstol, maxit, taufac, eta, neta, &
                  lunrpt, ipr1, ipr2, ipr2f, ipr3, &
                  wss, rvar, idf, &
                  tau, alpha, niter, nfev, njev, int2, olmavg, &
                  rcond, irank, actrs, pnorm, prers, rnorms, istop)

      ! Encode existance of questionable results into info
      if (info <= 9 .or. info >= 60000) then
         if (msgb(1) == 1 .or. msgd(1) == 1) then
            info = info + 1000
         end if
         if (istop /= 0) then
            info = info + 100
         end if
         if (irank >= 1) then
            if (npp > irank) then
               info = info + 10
            else
               info = info + 20
            end if
         end if
      end if

      ! Print final summary
      if (ipr3 /= 0 .and. lunrpt /= 0) then
         iflag = 3

         if (ipr3 >= 3 .and. lunrpt /= ludflt) then
            npr = 2
         else
            npr = 1
         end if
         if (ipr3 >= 6) then
            ipr = 2
         else
            ipr = 2 - mod(ipr3, 2)
         end if
         lunr = lunrpt
         do i = 1, npr
            call dodpcr(ipr, lunr, &
                        head, prtpen, fstitr, didvcv, iflag, &
                        n, m, np, nq, npp, nnzw, &
                        msgb, msgd, beta, y, ldy, x, ldx, delta, &
                        we, ldwe, ld2we, wd, ldwd, ld2wd, &
                        iwork(jpvt), ifixx, ldifx, &
                        lower, upper, &
                        ssf, tt, ldtt, stpb, stpd, ldstpd, &
                        job, neta, taufac, sstol, partol, maxit, &
                        wss, rvar, idf, work(sd), &
                        niter, nfev, njev, actred, prered, &
                        tau, pnorm, alpha, f, rcond, irank, info, istop)
            if (ipr3 >= 5) then
               ipr = 2
            else
               ipr = 1
            end if
            lunr = ludflt
         end do
      end if

   end subroutine dodmn

end module odrpack
