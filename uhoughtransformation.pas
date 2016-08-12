unit uHoughTransformation;
{*******************************************************************************
 *
 *
 *   a PASCAL / DELPHI implementaion of the Hough Image Transformation Algorithm
 *
 *
 *
 *   initial code version :   03.04.2011 by BDLM
 *
 *   rev 0.01  :   this is the first release for circle and line detection
 *                 on simple test images this implemention will create good results
 *                 but due to the lack of any post processing code on the Accumulator
 *                 results this unit is not able to process complex images
 *
 *******************************************************************************}


interface

uses   SysUtils, Variants, Classes, Graphics, Controls,
       StdCtrls, ExtCtrls, Menus, Math, ExtDlgs, ComCtrls,
       StrUtils, Contnrs;





type

      ///  2 D coordinate definition, Float data type
      FPoint = record
               X: Real;   ///  X value
               Y: Real;   ///  Y value
               end;




      ///  3 D coordinate definition  (integer values)
      THPoint3D  = record
                x :  integer;
                y :  integer;
                z :  integer;
                Z1:  integer;    ///  only for debug Hough transformation  .... ugly code !!!!!
                end;



     THoughResult = array of array of Integer;
     THoughFinal = Array of THPoint3D;
     TImageContentList = TObjectList;


    /// Hough Transformation  -> Algo for Line detection
    procedure Hough_LineDetection ( AnalysisBitmap : TBitMap; var aHoughResult :  THoughResult );

    /// Hough Transformation  -> Algo for Circle  detection
    procedure Hough_CircleDetection ( AnalysisBitmap : TBitMap; var aHoughResult :  THoughResult ;  r  :  Integer  );

    ///  show accumulator Box
    procedure HoughresultToBitMap (ResultBitmap : TBitMap; aHoughResult :  THoughResult );

    /// screen for maxima inside the Hough accu box
    procedure  HoughResultToParameter(aHoughResult :  THoughResult; Range : Real; var aHoughFinal : THoughFinal );

    ///  does a pixel have a certain value or not ???
    function IsPixel(xpos, ypos : Integer; aBitmap : TBitMap; ThresHold   :  Integer ) : boolean;

    /// increase sensitivity
    procedure  HoughResultToParameterDynamic(aHoughResult :  THoughResult; Range : Real; var aHoughFinal : THoughFinal );


    ///  show accumulator Box as lines
    procedure HoughResultLineParameterToBitMap (var aAnalysisBitmap : TBitMap; aHoughFinal : THoughFinal );


    ///  show accumulator Box as circles
    procedure HoughResultCircleParameterToBitMap (var aAnalysisBitmap : TBitMap; aHoughFinal : THoughFinal; aRadius : Integer );


    ///  convert the Lines into TThicklines ObjectList
    procedure HoughResultLineParameterToObjectArray (aAnalysisBitmap : TBitMap; aHoughFinal : THoughFinal; aImageContentList : TImageContentList  );


    ///  set aq values insde the HOUGH array to ZERO
    function ResetArray (var aHoughResult :  THoughResult  ) : Integer;

implementation




///
///   check if there is a pixel or not ....
///
///   rgb (white) = (255 | 255 | 255 )
///   rgb (black) = ( 0| 0 | 0 )
///
///
function IsPixel(xpos, ypos : Integer; aBitmap : TBitMap; ThresHold   :  Integer ) : boolean;
var  p     :  pbyteArray;
     r,g,b, mean  :  Integer;
begin

  aBitmap.PixelFormat := pf24bit;

  if (ypos <= aBitmap.Height-1)   and  (xpos <= aBitmap.Width-1) then

    begin
      p:= aBitmap.ScanLine[ypos];

      r := p[3 * xpos ];
      g := p[3 * xpos + 1];
      b := p[3 * xpos + 2];
      mean := ( (round(r) + round(g) + round(b)) div 3);

      if ( mean > ThresHold ) then result := true
                              else result := false;

    end
    else
    begin
       result := false
    end;



end;







///
///   Hough transformation for line detection
///   r =  sin(theta) * a + cos(theta) * b
///
///
procedure Hough_LineDetection ( AnalysisBitmap : TBitMap; var aHoughResult :  THoughResult  );
var x,y, theta  : integer;
    r           : Extended;
    ImageWidth  : integer;
    ImageHeight : Integer;
    max_d       : Integer;
    max_theta   : Integer;
begin



   ///  size of hough array
   ImageWidth := AnalysisBitmap.Width;
   ImageHeight:= AnalysisBitmap.Height;

   max_d := round( sqrt( ImageHeight* ImageHeight + ImageWidth * ImageWidth   ) ) ;
   max_theta := 180;


   //                       phi         r
   SetLength(aHoughResult,max_theta, max_d );

   // For all rows in image do :
   for y:=0 to AnalysisBitmap.Height-1 do
   begin

   // For all pixel in one row do :
   for x:=0 to AnalysisBitmap.Width-1 do
   begin

      // Is there a point there or not ?  If not, just skip the pixel ( threshold based methode ...)
      if IsPixel(x, y, AnalysisBitmap, 128 ) then
      begin
           // iterate the unknown variables :   ( r, theta )
           // loop theta ->  to be able to determine the other unknown -> r
           for theta:=0 to max_theta do
           begin
                r:=x*cos(theta*PI/max_theta) + y*sin(theta*PI/max_theta);

                // Plot the finding (theta,r) into an array.
                // Ignore negative values...
                //
                if r>=0 then Inc(aHoughResult[theta,round(r)]);
           end;
      end;
   end;
  end;


end;




///
///   Hough transformation for circle detection
///
///
///   AnalysisBitmap : TBitMap;         ->  the image  for hough tranmsformation
///   aHoughResult   :  THoughResult    ->  the result of the Hough transformation  array of array of integer
///   r              :  Integer;        ->  the search radius
///
///


procedure Hough_CircleDetection ( AnalysisBitmap : TBitMap; var aHoughResult :  THoughResult ;  r  :  Integer  );
var x,y         : integer;
    ImageWidth  : integer;
    ImageHeight : Integer;
    theta       : Integer;
    max_theta   : Integer;
    Box_LL      : FPoint;
    Box_UR      : FPoint;
    TestPoint   : TPoint;
begin


   ///  size of hough array
   ImageWidth := AnalysisBitmap.Width;
   ImageHeight:= AnalysisBitmap.Height;

   ///
   Box_LL.X  := 0;
   Box_UR.y  := 0;

   Box_UR.X := ImageWidth;
   Box_UR.Y := ImageHeight;

   max_theta := 360;
                            //  a        //  b
   SetLength(aHoughResult,ImageWidth, ImageHeight );

   // For all rows in image:
   for y:=0 to AnalysisBitmap.Height-1 do
   begin

   // For all pixel in one row :
   for x:=0 to AnalysisBitmap.Width-1 do
   begin

      // Is there a point  ?
      if IsPixel(x,y, AnalysisBitmap, 128 ) then
      begin

           for theta:=0 to max_theta do
           begin

                TestPoint.x := round ( x -  r  *  cos(theta*PI/max_theta) );
                TestPoint.y := round ( y -  r  *  sin(theta*PI/max_theta));

               //  if  IsPointInBox( Box_LL , Box_UR, testPoint ) then Inc(aHoughResult[x,y]);

               if ((testPoint.x < ImageWidth) and  (testPoint.x > 0 )  and
                  (testPoint.y < ImageHeight ) and  (testPoint.y > 0 ) )   then Inc(aHoughResult[TestPoint.x,TestPoint.y]);

           end;
      end;
   end;
  end;


end;






///
///  Max_Array  2D Integer array  , very simple scan through the hole array
///
function MAX_2D ( aHoughResult :  THoughResult  ) : Integer;
var   n,m      :  Integer;
      i,j      :  Integer;
      max      :  Integer;
begin
     n := length(aHoughResult);
     m := length(aHoughResult[0]);

     max :=  aHoughResult[0][0];

     for i:= 0 to n -1 do
      for j := 0 to m-1 do
        if aHoughResult[i][j] > max then
             max :=aHoughResult[i][j];

     result :=  max;

end;





///
///  MEAN_Array  2D Integer array
///

function MEAN_2D_Local ( aHoughResult :  THoughResult; x_pos, y_pos, x_size, y_size : Integer   ) : Integer;
var   n,m      :  Integer;
      i,j      :  Integer;
      mean      :  Integer;
begin
     n := length(aHoughResult);
     m := length(aHoughResult[0]);

     mean := 0;

     if ((x_pos>=(n-x_size)) or (y_pos>=(m-y_size))) then
                         begin
                         result := 0;
                         exit;
                         end;


     for i:= x_pos to x_pos + x_size do
       for j := y_pos to y_pos + y_size do
                    mean :=mean + aHoughResult[i][j];

     result := round( mean / ((x_size+1) * (y_size+1))) ;

end;




///
///  MAX_Array  2D Integer array
///

function MAX_2D_Local ( aHoughResult :  THoughResult; x_pos, y_pos, x_size, y_size : Integer   ) : Integer;
var   n,m      :  Integer;
      i,j      :  Integer;
      max      :  Integer;
begin
     n := length(aHoughResult);
     m := length(aHoughResult[0]);



     if ((x_pos>=(n-x_size)) or (y_pos>=(m-y_size))) then
                         begin
                         result := 0;
                         exit;
                         end;

     max :=  aHoughResult[x_pos][y_pos];

     for i:= x_pos to x_pos + x_size do
       for j := y_pos to y_pos + y_size do
            if aHoughResult[i][j] > max then
                        max :=aHoughResult[i][j];

     result := max;

end;







///
///  Min_Array  2D Integer array
///
function MIN_2D ( aHoughResult :  THoughResult  ) : Integer;
var   n,m      :  Integer;
      i,j      :  Integer;
      min      :  Integer;
begin
     n := length(aHoughResult);
     m := length(aHoughResult[0]);

     min :=  aHoughResult[0][0];

     for i:= 0 to n -1 do
      for j := 0 to m-1 do
        if aHoughResult[i][j] < min then
                min :=aHoughResult[i][j];

     result :=  min;

end;



///
///  clear result array
///
function ResetArray (var aHoughResult :  THoughResult  ) : Integer;
var   n,m      :  Integer;
      i,j      :  Integer;
      //min      :  Integer;
begin
     n := length(aHoughResult);
     m := length(aHoughResult[0]);

     //min :=  aHoughResult[0][0];

     for i:= 0 to n -1 do
      for j := 0 to m-1 do
           aHoughResult[i][j] := 0 ;
     result := 1;

end ;



///
///     copy the Hough Accumulator into a 3D INT Array Data type
///     in :
///     aHoughResult   ->  the Hough accu
///     range [ 0..1]
///     out:
///     aHoughFinal     list of points above the max
///                     [x,y,z]
///
///
procedure  HoughResultToParameter(aHoughResult :  THoughResult; Range : Real; var aHoughFinal : THoughFinal );
var   n,m      : Integer;
      i,j      : Integer;
      MAX      : Integer;
      MAXR     : Real;
      resultlen : Integer;
begin

     n := length(aHoughResult);
     m := length(aHoughResult[0]);

     resultlen := 0;

     Max := MAX_2D(aHoughResult);
     if ( max = 0)  then max := 1 ;


     MaxR :=  Max * Range;


     for i:= 0 to n-1 do
       for j:= 0 to m-1 do
         if (aHoughResult[i,j] > MaxR ) then
           begin

           setlength (aHoughFinal, resultlen+1);

           aHoughFinal[resultlen].x := i;

           aHoughFinal[resultlen].y := j;

           aHoughFinal[resultlen].z := aHoughResult[i,j];

           resultlen  := resultlen + 1;

           end;


end;



///
///    as above, but now with dynamic thresholding
///              http://homepages.inf.ed.ac.uk/rbf/HIPR2/histeq.htm
///              http://homepages.inf.ed.ac.uk/rbf/HIPR2/hough.htm
///
///

procedure  HoughResultToParameterDynamic(aHoughResult :  THoughResult; Range : Real; var aHoughFinal : THoughFinal );
var   n,m      : Integer;
      i,j      : Integer;
      MAX      : Integer;
      Mean     : Integer;
      MAXR     : Real;
      resultlen : Integer;
      Grad     : Integer;
      Grad_Min : Integer;
begin

     n := length(aHoughResult);
     m := length(aHoughResult[0]);

     resultlen := 0;

     Grad_Min := 30 ;


     for i:= 0 to n-1 do
       for j:= 0 to m-1 do
       begin

       Max :=  MAX_2D_Local (aHoughResult, i,j, 10, 10 );

       mean := MEAN_2D_Local (aHoughResult, i,j, 10, 10 );

       Grad := (Max - Mean);

       MaxR :=  Max * Range;


         if ((aHoughResult[i,j] > MaxR ) and (Grad > Grad_min)) then
           begin

           setlength (aHoughFinal, resultlen+1);

           aHoughFinal[resultlen].x := i;

           aHoughFinal[resultlen].y := j;

           aHoughFinal[resultlen].z := aHoughResult[i,j];

           aHoughFinal[resultlen].Z1 := Round(MaxR);

           resultlen  := resultlen + 1;

           end;
        end;

end;





///
///   all bright points represet a line ---  you need to draw them now ....
///
///


procedure HoughResultLineParameterToBitMap (var aAnalysisBitmap : TBitMap; aHoughFinal : THoughFinal );
var     lenArray ,i  :  Integer;
        s, c         :  Extended;
        dx,dy        :  Integer;
        angle        :  Integer;
        Radius       :  Integer;
        MPoint       :  TPoint;
        maxlen          :  Integer;

begin
        lenArray := length(aHoughFinal);

        maxlen := max( aAnalysisBitmap.Width, aAnalysisBitmap.Height);

        for i := 0 to lenArray - 1 do
          begin

          angle := aHoughFinal[i].x;

          Radius := aHoughFinal[i].y;

          sincos(degtorad(angle), s, c);

          MPoint := Point( round(c * radius), Round ( s* radius) );

          sincos(degtorad(angle + 90), s, c);

          dx := round(c *  maxlen);

          dy := round(s *  maxlen);

          With aAnalysisBitmap.canvas Do
             Begin

              pen.color := clRed;

              moveto(Mpoint.X+dx, Mpoint.Y+dY);

              lineto(Mpoint.X-dx, Mpoint.Y-dY);
             End;



          end;


end;




///
///
///     the Hough Array only contains the line - without start and ending coordinates - scan the line inside the *.bmp
///     for starting and ending point
///     NOT YET IMPLEMENTED NEED CODE SUPPORT HERE !!!!!
///

procedure HoughResultLineParameterToObjectArray (aAnalysisBitmap : TBitMap; aHoughFinal : THoughFinal; aImageContentList : TImageContentList  );
var     lenArray ,i  :  Integer;
        //angle        :  Integer;
        //Radius       :  Integer;
        //maxlen       :  Integer;


begin
        lenArray := length(aHoughFinal);

        //maxlen := max( aAnalysisBitmap.Width, aAnalysisBitmap.Height);

        for i := 0 to lenArray - 1 do
          begin

          // angle := aHoughFinal[i].x;

          // Radius := aHoughFinal[i].y;

          // aLine := TThickline.Create;

          // aImageContentList.Add(aLine)

          end;
end;





///
///
///

procedure HoughResultCircleParameterToBitMap (var aAnalysisBitmap : TBitMap; aHoughFinal : THoughFinal; aRadius : Integer );
var     lenArray ,i  :  Integer;
        a,b          :  Integer;

        //maxlen          :  Integer;

begin
        lenArray := length(aHoughFinal);

        //maxlen := max( aAnalysisBitmap.Width, aAnalysisBitmap.Height);

        aRadius := round( aRadius / 4 );

        for i := 0 to lenArray - 1 do
          begin

          a := aHoughFinal[i].x;

          b := aHoughFinal[i].y;

          With aAnalysisBitmap.canvas Do
             Begin

              pen.color := clRed;

              ellipse (a+aRadius , b+ aRadius, a-aRadius , b - aRadius );

             End;

          end;

end;



///
///     copy the Hough Accumulator into a 2D INT Array Data type
///

procedure HoughresultToBitMap (ResultBitmap : TBitMap; aHoughResult :  THoughResult );
type   PixArray = Array [1..3] of Byte;
var   n,m      :  Integer;
      p        : ^PixArray;
      h,w      : Integer;
      xquer    : Integer;
      MAX      : Integer;
begin

     n := length(aHoughResult);
     m := length(aHoughResult[0]);

     ResultBitmap.Width := n;    //  1. parameter
     ResultBitmap.height := m;   //  2. Parameter


     Max := MAX_2D(aHoughResult);
     if ( max = 0)  then max := 1 ;

     ResultBitmap.PixelFormat := pf24bit;

     For h:=0 to ResultBitmap .Height-1 do
       begin
       p:= ResultBitmap.ScanLine[h];
       For w:=0 to ResultBitmap .Width-1 do
       begin
        xquer := Round( aHoughResult[w,h] / Max * 255 )  ;
        p^[1] := xquer;
        p^[2] := xquer;
        p^[3] := xquer;
        Inc(p);
        end;
     end;
end;






end.
