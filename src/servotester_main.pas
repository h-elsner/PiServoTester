(*
Servo input:
PWM wird üblicherweise zwischen 1100-1900µs genutzt.
Mittenstellung: 1500µs
Maximal ist es bei Analogservos 900-2100µs.
Die PWM Impulse werden alle 20ms (50Hz) gesendet.

Bei Yuneec:
untere Stellung der Sticks: 	 683=-100%
Mittelstellung:		        2048=0%
obere Stellung der Sticks: 	3412=+100%




HW-PWM auf GPIO18:
   dtoverlay=pwm,pin=18,func=2
in /boot/config.txt eintragen und reboot.



*)

unit servotester_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Buttons, A3nalogGauge, SR24_ctrl;

type

  { TForm1 }

  TForm1 = class(TForm)
    cbRange: TCheckBox;
    ggServo: TA3nalogGauge;
    lblPulse: TLabel;
    rgFreq: TRadioGroup;
    rgPulse: TRadioGroup;
    tbPulse: TTrackBar;
    procedure cbRangeChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure lblPulseDblClick(Sender: TObject);
    procedure rgFreqClick(Sender: TObject);
    procedure rgPulseClick(Sender: TObject);
    procedure tbPulseChange(Sender: TObject);
  private
    procedure SetSchieber(min1, min2, mitte, max2, max1: integer);
    procedure SetSchieberDefault;
    procedure PulseSettings;
  public
    function MysToProz(mys: integer): single;      {Pulsbreite in µs in Prozent umrechnen}
    function InitPWM: integer;                     {PWM0 erzeugen und freigeben}
  end;

var
  Form1: TForm1;

  const
  capForm='Pi Servotester PWM';
  capFreq='Ansteuerfrequenz';
  capPulse='Pulsebreite per 100%';
  capRange='Erlaube +/-150%';
  rsPWMpulse='PWM Pulsbreite';
  neutral1=1500;
  neutral2=2048;
  mys='µs';
  tab1=' ';


implementation

{$R *.lfm}

procedure SetPWM(p: integer);
begin
  SetPWMCycle(0, p*1000);
end;

function TForm1.MysToProz(mys: integer): single;      {Pulsbreite in µs in Prozent umrechnen}
begin
  case rgPulse.ItemIndex of
    0: result:=(mys-neutral1)/4;
    1: result:=(mys-neutral1)/6;
    2: result:=(mys-neutral2)/13.64;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption:=capForm;
  rgFreq.Caption:=capFreq;
  rgPulse.Caption:=capPulse;
  cbRange.Caption:=capRange;
  ggServo.IndMinimum:=-100;
  ggServo.IndMaximum:=100;
  cbRange.Checked:=false;
  InitPWM;
end;

procedure TForm1.lblPulseDblClick(Sender: TObject);
begin
  if rgPulse.ItemIndex=2 then
    tbPulse.Position:=neutral2
  else
    tbPulse.Position:=neutral1;
  tbPulse.SetFocus;
end;

procedure TForm1.rgFreqClick(Sender: TObject);
begin
  case rgFreq.ItemIndex of
    0: SetPWMPeriod(0, 20000000);
    1: SetPWMPeriod(0, 14285714);
    2: begin
         SetPWMPeriod(0, 3333333);
         if rgPulse.ItemIndex=2 then begin
           rgPulse.ItemIndex:=0;
         end;
       end;
  end;
  tbPulse.SetFocus;
  PulseSettings;
end;

procedure TForm1.SetSchieber(min1, min2, mitte, max2, max1: integer);
begin
  if cbRange.Checked then begin
    tbPulse.Max:=max1;
    tbPulse.Min:=min1;
    tbPulse.ShowSelRange:=true;
  end else begin
    tbPulse.Max:=max2;
    tbPulse.Min:=min2;
    tbPulse.ShowSelRange:=false;
  end;
  tbPulse.SelEnd:=max2;
  tbPulse.SelStart:=min2;
  tbPulse.Position:=mitte;
  tbPulse.SetFocus;
  tbPulse.Refresh;
end;

procedure TForm1.PulseSettings;
begin
  case rgPulse.ItemIndex of
    0: SetSchieberDefault;
    1: SetSchieber(600, 900, neutral1, 2100, 2400);
    2: SetSchieber(0, 683, neutral2, 3412, 4096);
  end;
  SetPWM(tbPulse.Position);
end;

procedure TForm1.SetSchieberDefault;
begin
  SetSchieber(900, 1100, neutral1, 1900, 2100);
  lblPulse.Caption:=rsPWMpulse+' 1500µs = 0%';
end;

procedure TForm1.rgPulseClick(Sender: TObject);
begin
  PulseSettings;
end;

procedure TForm1.tbPulseChange(Sender: TObject);
var
  w: integer;

begin
  w:=tbPulse.Position;
  if w=0 then
    w:=1;
  if ((w*1000)<3333330) or (rgFreq.ItemIndex<2) then begin
    ggServo.Position:=MysToProz(w);
    lblPulse.Caption:=rsPWMpulse+tab1+IntToStr(w)+mys+
                      tab1+'='+tab1+FormatFloat('0.0', ggServo.Position)+'%';
    SetPWM(w);
  end;
end;

procedure TForm1.cbRangeChange(Sender: TObject);
begin
  PulseSettings;
  tbPulse.SetFocus;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  SetSchieberDefault;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  DeactivatePWM;
end;

function TForm1.InitPWM: integer;                        {PWM0 erzeugen und freigeben}
begin
  result:=ActivatePWMChannel(false);                     {Enable PWM0}
  Application.ProcessMessages;
  SetPWMChannel(0, 20000, 1500000, false);
end;

end.

