---
title: "Streaming Pair Programming from AWS"
date: 2020-04-19T09:56:08+01:00
draft: true
tags: ["twitch", "aws", "teamviewer", "pair programming", "zoom", "coq", "vscode"]
---

## Why?

  - **Why Streaming?** One of the advantages of living in a big city, like London, is not just that you don't have to own a car, but it makes it easier to find people, who are interested in learning the same thing you are and who are at a similar level in their learning experience on the topic. People you can form a study group with. I remember that working in, Stellenbosch, South Africa, I had to drive an hour and a half, one way, to Scarborough, Cape Town to find a group of about ten people interested in functional programming.  
<center>
<iframe src="https://www.google.com/maps/embed?pb=!1m28!1m12!1m3!1d1757916.0067339428!2d17.632468364941275!3d-34.08608619022217!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!4m13!3e0!4m5!1s0x1dcdb2f75188e2a5%3A0x7009aa00dee36be2!2sStellenbosch%2C%20South%20Africa!3m2!1d-33.9321045!2d18.860152!4m5!1s0x1dcc14ff23836223%3A0xc728558c5dcf53ac!2sZensa%20Lodge%2C%20534%20Egret%20St%2C%20Scarborough%2C%207975%2C%20South%20Africa!3m2!1d-34.199730699999996!2d18.375520599999998!5e1!3m2!1sen!2suk!4v1587292763786!5m2!1sen!2suk&zoom=20" width="600" height="450" frameborder="0" style="border:0;" allowfullscreen="" aria-hidden="false" tabindex="0"></iframe>
</center>
  Things have since changed with regards to functional programming at Stellenbosch University, where Haskell is now being taught in a popular choice module, but what if I wanted to study Coq programming next.  What if there was a way to share some of the London study group with others?  First idea, Twitch seems to be a low expectations, low effort, somewhat popular way for sharing your programming process.

  - **Why Pair programming?** Pair programming on a Coq project, where I am still learning the language, libraries and not to mention the underlying theory, has been more educational to me than I could have imagined.  If I was to share something, the pair programming had to be part of it, as this was where I was getting most value and I don't want to lose that.

  - **Why AWS?** tl;dr more CPU! A friend from the study group and I started pair programming some Saturdays, this evolved into a video call, where it was easy to include the whole study group. Video calling in general is not, lets say CPU friendly and Zoom is no exception.  If you are then also running OBS (the streaming software), you have two programs both competing for 250% of your 400% CPU.  At some point typing in VSCode felt like I was typing in a remote terminal over a dial up modem.

What if we could rent a beast of a machine on AWS and run everything there, the VSCodes, the Zooms and the OBSs.  They would then end up using only 25% CPU, including Teamviewer.

## Setup

I thought streaming pair programming was going to be easy. 
I thought it would be as easy as Ted's setup for [remote pair programming on twitch with zoom](https://www.tedmyoung.com/remote-pair-programming-on-twitch-with-zoom/).  All running on my local machine.
I never thought I would run out of CPU and need an AWS, but here we are and here is my longer than expected setup process, which I almost gave up when I was 90% done.  After this things are running smoothly, but there are several loop holes to jump through and I thought I'd better document it, in case I need to reproduce it, but also for others who might be interested.

1. Find an appropriate AWS machine.
2. Ask amazon to lift CPU limit.
3. Update security group to enable remote desktop
4. Log in using remote desktop
5. Update internet explorer security
6. Install and setup Teamviewer
7. Install virtual sound card
8. Install and setup Zoom
9. Install and setup OBS
10. Install and setup IDE

Disclaimer: My home computer is a mac, so some of this setup is geared towards catering for a osx, but even more significantly since I chose a windows machine as my AWS server, a lot of this is specific to having windows as your remote machine.

### Find an appropriate AWS machine

I found the
[Microsoft Windows Server 2016 with NVIDIA GRID Driver](https://aws.amazon.com/marketplace/pp/Amazon-Web-Services-Microsoft-Windows-Server-2016-/B073WHLGMC) machine. It is a `g3.4xlarge`, which has 16 cores.
This setup with 16 cores ended up running at 25% CPU, so I wouldn't recommend a 4 core machine.  I chose windows over linux, because this is "the year of the linux desktop".  If you are new to AWS, you won't be able to launch this yet and you will need to increase your CPU limit, see instructions in the next section.

This server looks expensive and it is not cheap, but given you are only paying for it when it is running, if you are disciplined in stopping the server, when you are not using it, it can be affordable, depending on how much you intend to use it.  Now is a good time to make that calculation and decide whether you can live with the hourly rate, which is about $2 per hour, at the time of writing.

### Ask Amazon to lift CPU Limit

  - Create an AWS account of log into your existing one by going to your [AWS Console](https://console.aws.amazon.com/)
  - At the top, click `Services` and from the menu under `Compute` select [EC2](https://console.aws.amazon.com/ec2)
  - On the side menu, click `Limits`
  - Search for CPU and select `Running On-Demand All G instances`, this is if you also chose a machine that starts with `g`, like the `g3.4xlarge`.  If you are new to AWS, like me, you will need to increase your `Current Limit` of `0` to `16` to be able to launch the chosen machine.  If your limit is already high enough you can skip this section.
  ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/AWSLimits.png "Limits")
  - Click `Request limit increase` in the top corner.
  - A form will open:
    + Make sure `EC2 Instances` is selected for `Limit type`
  ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/AWSCaseClassification.png "CaseClassification")
    + Select your Region, `All G instances` if you are requesting a machine that starts with `g`, like the `g3.4xlarge`.  Choose a `New limit value` of `16` if that is appropriate for your selected machine, like the `g3.4xlarge`.
  ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/AWSRequests.png "Requests")
    + Finally describe your use case in the `Use case description` box.
  ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/AWSCaseDescription.png "CaseDescription")
  - And now you will have to wait for amazon's human reviewers to look at the case and decide whether to increase the limits.  I waited about 3 days.
  - Then you should be able to launch in the instance.

## Update security group to enable remote desktop

AWS Windows servers don't let you log into them using remote desktop by default.
You have to create a new security group or update the default security group to allow for RDP traffic.

  - go to [AWS Console](https://console.aws.amazon.com/)
  - go to [EC2](https://console.aws.amazon.com/ec2)
  - On the left, under `Network & Security`, click on `Security Groups`.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/SecurityGroups.png "SecurityGroups")
  - `Create security group` or `Edit Inbound Rules` of an existing group. To edit an existing group, for example the `default` Security group: Select it, click on `Actions` and then `Edit Inbound Rules`.
  -  Next you will need to add two new rules, using the `Add Rule` button:
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/AWSRDP.png "AWS RDP Rules")
    `Type: RDP, Source: 0.0.0.0/0` and `Type: RDP, Source: ::/0`
  - Finally click `Save rules`. Now you should be able to use remote desktop to log into your server.

## Launch and log into server using Remote Desktop

  - If you are on a mac, you will need to install [remote desktop](https://apps.apple.com/us/app/microsoft-remote-desktop-10/id1295203466?mt=12).
  - Now is the time launch your instance
    [Microsoft Windows Server 2016 with NVIDIA GRID Driver](https://aws.amazon.com/marketplace/pp/Amazon-Web-Services-Microsoft-Windows-Server-2016-/B073WHLGMC)
    + click on `Continue to Subscribe`.  This doesn't cost anything for this specific instance, since it is an instance marketed by AWS themselves, but other instances on AWS Marketplace, might cost a subscription fee.
    + click on `Continue to Configuration`
    + pick your specific region, we chose `EU (Ireland)`.
    + check that the `Software Pricing` is `$0/hr` if you haven't chosen a different machine. `Infrastructure Pricing` should have a real cost associated with it.
    + click on `Continue to Launch`
  - go to [EC2](https://console.aws.amazon.com/ec2)
  - click on Instances on the left side menu.
  - Now the machine might already be started, or initializing, but if is not, then right click on the instance, select `Instance State` and then `Start`.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/Instances.png "Instances")
  - Wait for `Status Checks` to turn from `Initializing` to `2/2 checks passed`.
  - Right click on your machine and click `Connect`
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/Connect.png "Connect")
  - Click on `Download Remote Desktop File`
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/DownloadRemoteDesktopFile.png "DownloadRemoteDesktopFile")
  - You will also need to `Get Password`, but that I will leave up to you.
  - Now open the downloaded remote desktop file, using remote desktop.
  - You will need to paste in the password you got from `Get Password`.
  - Well done you can now remotely control the AWS windows server, from your home computer, using remote desktop.
  - Before you possibly stop your server, remember to create an image in the AWS E2 Instances.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/CreateImage.png "CreateImage")

## Update Internet Explorer security

This first problem you will encounter on your windows server, is Internet Explorer has been severely limited, via a security setting.  Basically, you won't even be able to download a real browser. Lets fix that.

On your windows server, via Remote Desktop:

  - Open `Server Manager`
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/ServerManager.png "ServerManager")
  - In the left panel, Select `Local Server`
  - In the top panel with heading `Properties`, in the right middle of the window, you will see `IE Enhanced Security Configuration`.  Mine already, says `Off`, but yours will say `On`.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/IEEnhanced.png "IEEnhanced")
  - Click on `On` and select `Off` for both users and Administrator.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/InternetExplorerEnhanced.png "InternetExplorerEnhanced")
  - Click `Ok`.
  - Close `Server Manager`
  - Open Internet Explorer, it should now show that `Caution: Internet Explorer Enhanced Security Configuration is Enabled`.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/InternetSecurityNotEnabled.png "InternetSecurityNotEnabled")
  - Download and install your browser of choice.

## Install Teamviewer

Why do we need Teamviewer, when Remote Desktop is working so well?  It all comes down to sound.  A server doesn't have a sound card, but we want to stream the sound from our video call to Twitch.  We will need to install a virtual sound card and this doesn't play nicely with Remote Desktop.  
I also chose Teamviewer over VNC, because we will need cloud connect for a user friendly experience and this is free for personal use on Teamviewer, where I found with VNC servers that it looked like I needed to pay.  I could be wrong.
In the end Teamviewer was more user friendly for me and solved the sound problem.

  - Install [Teamviewer](https://www.teamviewer.com/) on your mac and windows server.
  - On the windows server, Sign in or create a Teamviewer account and sign in.
  - On the windows server, Tick `Start Teamviewer with Windows` and `Easy access for ... is granted`.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/GrantEasyAccess.png "GrantEasyAccess")
  - On your mac, sign into your Teamviewer account.
  - You should now see the machine under `Computer & Contacts`.
  - Double Click on the machine to connect.
  - You should get a notification about `multiple monitors`.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/MultipleMonitors.png "MultipleMonitors"). This server has two virtual monitors, which is going to be very useful for streaming.  Click `Ok`.
  - You should now see a locked screen, that requires `Ctrl+Alt+Delete` to unlock.  Click on `Actions` in the top menu bar and then select `Ctrl+Alt+Delete`.
  - You should now be able to log into your Administrator account.  You might have a problem here, which is copy and paste is not working, at least it didn't work for me.
  - Click on `Actions` again in the top menu bar and then select `Send key combinations`
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/KeyCombinations.png "KeyCombinations"). Try again. You might still have a problem, just like me.  You are not alone.  We are going to try and fix it, at least I did fix it somewhat.  I never got pasting into the password textbox to work, but I did get `Ctrl` key combinations to start working.
  - Now is as good a time as any to create a user account.  If you are unable to log into Teamviewer, yet.  Go to remote desktop and create a user account, with a password, that you can remember and type without copying and pasting.  You can keep your Administrator account secure and only ever need to use it with Remote Desktop.  Only your user account will need to work with Teamviewer and might need a password that you can actually remember and type out.
  - Now you can use Teamviewer to log into your user account.
  - One more thing I would encourage you to Configure is to Optimize for speed over quality of image.  If you are planning to code, then typing is a big part of that and typing feedback can be very important. Go to Teamviewer's `Preferences`. Click on `Remote Control` and from the `Quality` dropdown, select `Optimize speed`.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/OptimizeSpeed.png "OptimizeSpeed")
  - If you have trouble sending `Ctrl` through Teamviewer from your mac, like me.  Here is something that worked for me and I don't understand why.
    + On your mac go to Keyboard Settings.
      ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/Keyboard.png "Keyboard")
    + Click on `Modifier Keys...`
    + Set `Control Key` to `Command`.
      ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/ModifierKeys.png "ModifierKeys")
    + Click `Ok`.
    This makes no sense to me, but after I did this, it was possible for me to use `Ctrl` after I logged into my user account, via Teamviewer.
    I think it just requires some fiddling, because I have since turned back the settings and the problem remains fixed.

## Install virtual sound card

On the windows server:

  - Download [VB-Audio Software's VB-Cable](https://www.vb-audio.com/Cable/). We don't need the VB-Cable A+B, etc. We only need the `VBCABLE_Driver_Pack43.zip`.
  - Unzip and run `VBCABLE_Setup_x64`.
  - In Teamviewer, go to your sound card settings, by right clicking in the bottom right corner on the little speaker and selecting `Playback devices`.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/LittleSpeaker.png "LittleSpeaker")
  - Under `Playback` you should see `Cable Input` by `VB-Audio Virtual Cable`.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/Sound.png "Sound")
    Please ignore the other playback devices, I tried several routes before realizing remote desktop was incompatible with virtual sound cards and I haven't taken the time to clean up the other virtual sound cards, I ended up not using or even evaluating.
  - The virtual sound card is now installed, we are going to use it to thread the zoom output sound into OBS input sound and stream this to Twitch.

## Install and setup Zoom or another Video Call program

I chose [Zoom](https://zoom.us/), because:

  - Zoom allows screen sharing and doesn't turn off your webcam to do so.  Screen sharing was important for pair programming, but could be superseded by more Teamviewer usage in future.
  - Zoom's window in which participants are viewed is the prettiest to put in a corner of your screen and has `always on top` enabled automatically.

I might reconsider this choice in future, since Zoom calls over 40 minutes are not free and removing this from the setup would moderately reduce the overall cost of this setup.

Whichever Video Call program you choose, it is important to setup the sound output.  Here is how I did it for Zoom, but you should easily be able to reproduce this with any Video Calling program.

  - Install Zoom on your windows server and create a new account.  You are going to need two accounts for Zoom. One for the windows server and one for your home computer.  Only the account that will be hosting the meetings will need to be a paid account, if you are planning on pair programming longer than 40 minutes at a time, like me.
  - Go to Zoom settings and then `Audio`.  Set the Speaker to `CABLE Input (VB-Audio Virtual Cable)`, the Microphone doesn't matter as we won't be using the server's microphone.
  ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/ZoomAudio.png "ZoomAudio")

Now Zoom will send its output, which should include everyone on the call's audio to `CABLE Input..`, which we are going to capture using `OBS`.

## Install and setup OBS

[OBS Studio](https://obsproject.com/) is used to Stream to Twitch, Youtube, etc. Now is probably a good time to skim through a [better blog](https://www.freecodecamp.org/news/lessons-from-my-first-year-of-live-coding-on-twitch-41a32e2f41c1/) to learn a bit more about OBS and how to use it.
There are also many videos that explains how to setup OBS.  We will not be going into that.  We will only be touching on the specific OBS configuration for this setup, namely how to route the audio and how to share our screen using the multiple monitors of this AWS Server.

  - Log into your windows server as Administrator. Installing OBS requires being logged in as Administrator, so I installed it using Remote Desktop.
  - Download and install [OBS Studio](https://obsproject.com/) and setup connection to Twitch.
  - After installation, we can log back into our user, using Teamviewer.
  - Go to `View` in the top menu bar, under `Active monitor`, click `Show all monitors`.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/ShowAllMonitors.png "ShowAllMonitors")
  - Open `OBS Studio` and drag it to the smaller second monitor.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/DualMonitors.png "DualMonitors").  Your OBS will be less interesting than mine, since mine is already setup. OBS will be running on the small `monitor 2` and we will be using `monitor 1` for everything we want to stream to Twitch.
  - We can capture the sound from zoom that we have routed to `CABLE Input (VB-Audio Virtual Cable)` in OBS, by first creating a Scene. Click the `+` button in the `Scene` panel.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/Scene.png "Scene")
  - Select our new scene and click the `+` button under `Sources` and select `Audio Output Capture`.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/AudioOutputCapture.png "AudioOutputCapture")
  - Select `Create New`, type a name and click `OK`.
  - Select the `Device` from the dropdown: `CABLE Input (VB-Audio Virtual Cable)` and click `OK`.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/Device.png "Device")
  - You should now be able to test the sound, by creating a Zoom call between your home computer and the windows server and see the green bar in the Audio Mixer move, when you talk.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/Mixer.png "Mixer")
  - We can capture `monitor 1`, by adding another Source.  Click the `+` under `Sources` and select `Display Capture`.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/DisplayCapture.png 
    "DisplayCapture")
  - Select `Create New`, type a name and click `OK`.
  - Select the `Device` from the drop down `Display 1...` and click `OK`.
    ![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/DisplayDevice.png 
    "DisplayDevice")
  - You can now test the sound and display by clicking the `Start Recording` button in OBS, creating a zoom call and watching and listening to yourself speak, by playing the recorded file.
    
## Install and setup IDE

This setup is specific to VSCode and Coq, but you can install any IDE for any programming language you want.

  - Install [VSCode](https://code.visualstudio.com/), [Coq](https://coq.inria.fr/) and [VSCoq](https://github.com/coq-community/vscoq)
  - Install [Live Share](https://marketplace.visualstudio.com/items?itemName=MS-vsliveshare.vsliveshare) if you want to do collaborative editing, instead of just having your pair programmers, be backseat coders.  Possibly a better way to do this is with multiple Teamviewer logins, but we still have to test that.

## Remapping keys

I use Autohotkey to remap my most popular mac shortcuts to windows shortcuts.
- Log in as Administrator.
- Install [AutoHotkey](https://www.autohotkey.com/) on your windows server.

Create a script file: mac.ahk
```ahk
;Autohotkey script

;Cmd+Up => Ctrl+Home
#Up::Send ^{Home}
;Cmd+Down => Ctrl+End
#Down::Send ^{End}
;Cmd+Left => Home
#Left::Send {Home}
;Cmd+Right => End
#Right::Send {End}
;Cmd+Shift+Left => Shift+Home
#+Left::Send +{Home}
;Cmd+ShiftRight => Shift+End
#+Right::Send +{End}
;Cmd+A => Ctrl+A
#a::Send ^a
#b::Send ^b
#c::Send ^c
#d::Send ^d 
#e::Send ^e
#f::Send ^f
#g::Send ^g
#h::Send ^h
#i::Send ^i
#j::Send ^j
#k::Send ^k
#l::Send ^l
#m::Send ^m
#n::Send ^n
#o::Send ^o
#p::Send ^p
;Cmd+Q => Alt+F4
#q::Send !{F4}
#r::Send ^r
#s::Send ^s
#t::Send ^t
#u::Send ^u
#v::Send ^v
;Cmd+W => Ctrl+F4
#w::Send ^{F4}
#x::Send ^x
#y::Send ^y
#z::Send ^z
#1::Send ^1
#2::Send ^2
#3::Send ^3
#4::Send ^4
#5::Send ^5
#6::Send ^6
#7::Send ^7
#8::Send ^8
#9::Send ^9
#0::Send ^0
```

This script has to run as Administrator, otherwise you will probably have problems.
Right click on the file and choose `Run as Administrator`.
I needed to have Teamviewer's `Send key combinations` enabled, others have reported the opposite so play around with this.