# Tomatoast Timer

A Pomodoro Timer implemented using Windows 10 Toast Notifications.

## Pre-Requisites

* Powershell v5 or above (ideally v7.1 or above to benefit from events capture)
* [BurntToast](https://github.com/Windos/BurntToast)

**BurntToast** shall be installed via the following command in PowerShell (Administrator mode):

```powershell
Install-Module -Name BurntToast
```

## Introduction

### Pomodoro Technique

[Pomodoro Technique](https://en.wikipedia.org/wiki/Pomodoro_Technique)
is a time management technique that promotes successive intervals of
focused work and small pauses to boost efficiency and avoid procrastination.

### Implementation

This implementation is using the recommended time intervals:

* Working for 25 minutes, followed by a short break
* Breaks are 5 minutes the first 3 times, and then 15 minutes the 4th time

In other words: W25 / R5 / W25 / R5 / W25 / R5 / W25 / R15 / ... (repeat)

## How to use

Launch the Powershell script **pomodoro.ps1**.

## Known Issue

* Don't click on the Toast Notification or the notification will disappear and the timer will stop

## In Progress

* Currently, pausing is not implemented
