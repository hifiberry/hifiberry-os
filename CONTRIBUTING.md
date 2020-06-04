# Contribution guidelines

HiFiBerryOS is an open source distribution and we're happy to include distributions from users.

## What we may or may not include

Ease-of-use is the main goal of HiFiBerryOS. We don't want to create another distribution with hundreds of settings 
that most users don't understand. That also means, we might just not implement something if we feel that it is hard 
to understand or hard to use for end users.

The best way to integrate features is fully automatic without the user having to configure something. We know that this
isn't always possible, but try to think about what settings are really needed for users. Don't add any settings that 90% 
of the users don't need and/or understand. 
Feel free to let expert users edit configuration files with settings that are rarely used

## Sound card support

You extension must be able to work with all supported HiFiBerry sound cards. This means that it needs to be able to handle
all common sample rates (44.1-192kHz) and sample foprmats (at least S11_LE, S24_LE, S32_LE)

## Additional players/services

Every music service need to report the status via MPRIS. It needs to support at least the "STOP" command.

## Before you start

We recommend to contact us at support@hifiberry.com before working on a new module. We might be able to give you some tips 
to make sure, your contribution will be accepted once your work is done.
