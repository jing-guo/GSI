module windht

!$$$ module documentation block
!
! module:     windht
! programmer: levine
!
! abstract: contains subroutines for addition of wind sensor
!           height for various providers and subproviders.
!           Generates lists of provider/subproviders and applies
!           these heights to wind observations if present.
!
! program history log:
!   2019-07-12  levine (first shot)
!
! subroutines included:
!   sub readin_wndht_list
!   sub init_wndht_lists
!   sub destroy_windht_lists
!
!  variable definitions:  ??
!
!  attributes:
!    language: f90
!    machine: IBM-WCOSS
!
!$$$ end documentation block

  use kinds, only: i_kind,r_kind,r_single,r_double
  use constants, only: ten,zero,r10

  implicit none

  private

  !variable declarations across routines go here
  logical listexist
  logical fexist
  integer(i_kind),parameter::nmax=60000_i_kind
  character(len=8),parameter::misprv="XXXXXXXX"
  character(len=8),parameter::allprov="allsprvs"
  real(r_kind),parameter:: bmiss = 1.0e9_r_kind


  character(len=16),allocatable,dimension(:)::provlist
  real(r_kind),allocatable,dimension(:)::heightlist
  integer(i_kind)::numprovs

  public readin_windht_list
  public init_windht_lists
  public destroy_windht_lists
  public find_wind_height

  logical::verbose=.true.

contains

  subroutine readin_windht_list(filename,fexist,ncount)

    !abstract: Read provider wind sensor heights into arrays for later processing

    implicit none

    !passed vars:
    character(len=80),intent(in)::filename
    logical,intent(out)::fexist
    integer(i_kind),intent(out)::ncount

    !local variables
    integer(i_kind)::meso_unit,n,reason
    character(len=16)::cstring
    character(len=8)::cprov,csubprov
    real(r_kind)::height

    !start subroutine
    ncount=0
    !initialize arrays
    allocate(provlist(nmax))
    allocate(heightlist(nmax))
    provlist(:)=misprv
    heightlist(:)=bmiss
    inquire(file=trim(filename),exist=fexist)
    if(fexist) then
       open(meso_unit,file=trim(filename),form='formatted')
       !initialize counter and reader
       n=0
       reason=0
       !read provider/subprovider/height file
       do while (reason.eq.0)
          read(meso_unit,423,iostat=reason) cprov,csubprov,height
          n=n+1
          if (n.gt.nmax) then
             print*, "WARNING: Exceeding maximum number of provider/subprovder combinations (current,max)=",n,nmax
             exit
          endif
          cstring=cprov//csubprov
          provlist(n)=cstring
          heightlist(n)=height
       end do
423    format(A8,2X,A8,2X,F5.2)
       ncount=n-1
       print*, "Number of provider/subprovider combinations:",ncount
       close(meso_unit)
    endif

  end subroutine readin_windht_list
  
  subroutine init_windht_lists

    !abstract: Initialize provider wind sensor height lists for later reading.

    implicit none

    !local variables
    integer(i_kind)::use_unit
    character(150)::cstring
    character(80)::filename

    filename='provider_windheight'
    inquire(file=trim(filename),exist=listexist)
    if(listexist) then
       call readin_windht_list(filename,fexist,numprovs)
       print*, "Second chance!  Number of provider/subprovider combinations=",numprovs
    else
       print*, "WARNING: Wind sensor height list file does not exist!"
       print*, "WARNING: Wind sensors will be assumed of height of 10 m AGL!"
    endif

  end subroutine init_windht_lists
  
  subroutine destroy_windht_lists
    
    !abstract: Destroy wind height arrays previously allocated
    
    implicit none

    if (listexist) then
       deallocate(provlist)
       deallocate(heightlist)
    endif
    
  end subroutine destroy_windht_lists

  subroutine find_wind_height(cprov,csubprov,finalheight)

    !abstract: Find provider and subprovider in pre-determined arrays
    !Then return wind sensor height
    !If provider/subprovider is not found, return default height of 10 m.

    implicit none

    character(len=8),intent(in)::cprov,csubprov
    real(r_kind),intent(out)::finalheight

    !local vars
    integer(i_kind)::i
    character(len=8)::tmpprov,tmpsubprov

    !sanity check
    if (.not.fexist) then
       print*, "WARNING: File containing sensor heights does not exist.  Defaulting to 10 m..."
       finalheight=r10
       return
    elseif(.not.listexist) then
       print*, "WARNING: List of providers not properly in memory.  Defaulting to 10 m..."
       finalheight=r10
       return
    elseif (numprovs.gt.nmax) then
       print*, "WARNING: Invalid number of provider/subprovider combinations (number,max)=",numprovs,nmax
       print*, "WARNING: Defaulting to 10 m wind sensor height!"
       finalheight=r10
       return
    endif

    do i=1,nmax
       if (i.gt.numprovs) then
          finalheight=r10
          return
       else
          tmpprov=provlist(i)(1:8)
          tmpsubprov=provlist(i)(9:16)
          if (cprov.eq.tmpprov.and.((tmpsubprov.eq.csubprov).or.(tmpsubprov.eq.allprov))) then
             finalheight=heightlist(i)
             return
          endif
       endif
    enddo

  end subroutine find_wind_height
  
end module windht
