! GenMask.f90
!
! Author : Joseph Schoonover
! E-mail : jschoonover@lanl.gov, schoonover.numerics@gmail.com
!
! Copyright 2017 Joseph Schoonover, Los Alamos National Laboratory
! 
! Redistribution and use in source and binary forms, with or without
! modification,
! are permitted provided that the following conditions are met:
! 
! 1. Redistributions of source code must retain the above copyright notice, this
! list of conditions and the following disclaimer.
! 
! 2. Redistributions in binary form must reproduce the above copyright notice,
! this list of conditions and the following disclaimer in the 
! documentation and/or other materials provided with the distribution.
! 
! 3. Neither the name of the copyright holder nor the names of its contributors
! may be used to endorse or promote products derived from this 
!  software without specific prior written permission.
! 
! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
! AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED 
! TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
! PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
! CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
! EXEMPLARY,  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
! PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
! BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
! LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
! NEGLIGENCE  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
! SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
!
! ////////////////////////////////////////////////////////////////////////////////////////////////

PROGRAM GenMask

! src/common/
USE CommonRoutines
! src/POP/
USE POP_Params_Class
USE POP_Mesh_Class


IMPLICIT NONE
   INTEGER, PARAMETER   :: nMasks = 2
   TYPE( POP_Params )   :: params
   TYPE( POP_Mesh )     :: mesh
   INTEGER              :: i, j, iMask
   INTEGER, ALLOCATABLE :: maskField(:,:,:)
   CHARACTER(400)       :: ncfile
   REAL(prec)           :: x, y, r


      CALL params % Build( )

      CALL mesh % Load( TRIM(params % meshFile)  )

      ALLOCATE( maskField(1:mesh % nX,1:mesh % nY,1:nMasks) )

      maskField = 0

      DO iMask = 1, nMasks

      DO j = 1, mesh % nY
         DO i = 1, mesh % nX

            x = mesh % tLon(i,j)
            y = mesh % tLat(i,j)
          
            IF( x >= 180.0_prec )THEN
               x = x -360.0_prec
            ENDIF
            ! Build a circular region around the Agulhas            
            r = sqrt( (x-20.0_prec)**2 + (y+40.0_prec)**2 )
            IF( iMask == 1 )THEN

               IF( r <= 20.0_prec )THEN
                  IF( r > 19.5_prec )THEN
                     IF( x >= 20.0_prec )THEN
                        maskfield(i,j,iMask) = -1 ! Prescribed Points
                     ELSE
                        maskfield(i,j,iMask) = 1
                     ENDIF
                  ELSE
                     maskfield(i,j,iMask) = 1  ! Interior Points
                  ENDIF
               ENDIF
           
            ELSE

               IF( r <= 20.0_prec )THEN
                  IF( r > 19.5_prec )THEN
                     IF( x <= 20.0_prec )THEN
                        maskfield(i,j,iMask) = -1 ! Prescribed Points
                     ELSE
                        maskfield(i,j,iMask) = 1
                     ENDIF
                  ELSE
                     maskfield(i,j,iMask) = 1  ! Interior Points
                  ENDIF
               ENDIF
            ENDIF


         ENDDO
      ENDDO
      ENDDO

      CALL WriteMaskField( mesh, maskField, TRIM(params % maskFile) )
      CALL mesh % Trash( )

CONTAINS
 SUBROUTINE WriteMaskField( mesh, maskfield, maskfile )

   IMPLICIT NONE
   TYPE( POP_Mesh ), INTENT(inout)      :: mesh
   INTEGER, INTENT(in)                  :: maskfield(1:mesh % nX, 1:mesh %nY,1:nMasks)
   CHARACTER(*), INTENT(in)             :: maskfile
   ! Local
   INTEGER :: start(1:2), recCount(1:2)
   INTEGER :: ncid, varid(1:nMasks), nMaskid, x_dimid, y_dimid, iMask
   CHARACTER(3) :: maskChar

      start    = (/1, 1/)
      recCount = (/mesh % nX, mesh % nY/)

      CALL Check( nf90_create( PATH=TRIM(maskfile),&
                               CMODE=OR(nf90_clobber,nf90_64bit_offset),&
                               NCID=ncid ) )
      CALL Check( nf90_def_dim( ncid, "nlon", mesh % nX, x_dimid ) )
      CALL Check( nf90_def_dim( ncid, "nlat", mesh % nY, y_dimid ) )
      CALL Check( nf90_def_var( ncid, "nMasks",NF90_INT, nMaskid ) )

      DO iMask = 1, nMasks
         WRITE( maskChar,'(I3.3)' )iMask
         CALL Check( nf90_def_var( ncid, "mask"//maskChar,NF90_INT,&
                               (/ x_dimid, y_dimid /),&
                                varid(iMask) ) )

         CALL Check( nf90_put_att( ncid, varid(iMask), "long_name", "Domain Mask" ) )
         CALL Check( nf90_put_att( ncid, varid(iMask), "units", "" ) )
      ENDDO

      CALL Check( nf90_enddef(ncid) )
 
      CALL Check( nf90_put_var(ncid, nMaskid, nMasks ) ) 

      DO iMask = 1, nMasks
         CALL Check( nf90_put_var( ncid, &
                                varid(iMask), &
                                maskfield(:,:,iMask), &
                                start, recCount ) )
      ENDDO

      CALL Check( nf90_close( ncid ) )


 END SUBROUTINE WriteMaskField


END PROGRAM GenMask

