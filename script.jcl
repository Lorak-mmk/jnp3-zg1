//ZG1 JOB CLASS=A,MSGCLASS=T,NOTIFY=&SYSUID
//*=======================================
//* First we check if our ESDS VSAM exists.
//*=======================================
//* EXIST checks if ZGVSAM.ESDS exists
//* If it doesn't - return RC > 0
//EXIST1 EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *,SYMBOLS=EXECSYS
 LISTC ENT('&SYSUID..ZGVSAM.ESDS')
/*
//STEPIF1 IF RC > 0 THEN
//* If dataset doesn't exist - create it.
//MVSAM EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *,SYMBOLS=EXECSYS
 DEFINE CLUSTER( -
     NAME(&SYSUID..ZGVSAM.ESDS) -
     NONINDEXED -
     TRACKS(3 3) -
     CONTROLINTERVALSIZE(2048) -
     ERASE -
     RECORDSIZE(130 150) -
 )
/*
//ENDIF1 ENDIF
//*
//*=======================================
//* Lets create PDS (if it doesnt exist)
//*=======================================
//* EXIST2 checks if ZGPDS.DSET exists
//* If it doesn't - return RC > 0
//EXIST2 EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *,SYMBOLS=EXECSYS
 LISTC ENT('&SYSUID..ZGPDS.DSET')
/*
//STEPIF2 IF RC > 0 THEN
//* MDSET creates our ZGPDS.DSET
//MDSET EXEC PGM=IEFBR14
//NEWDD DD DSN=&SYSUID..ZGPDS.DSET,
// DISP=(NEW,CATLG),
// SPACE=(CYL,(1,1,5)),LRECL=80,RECFM=FB,BLKSIZE=27920
//ENDIF2 ENDIF
//* We want to have some data in PDS to later copy it to VSAM
//* So let's write it to a member
//MCONT EXEC PGM=IEBGENER
//SYSUT1 DD *
 ZADANIE GRUPOWE
/*
//SYSUT2 DD DSN=&SYSUID..ZGPDS.DSET(MEMB1),DISP=(SHR)
//SYSIN DD DUMMY
//SYSPRINT DD DUMMY
//*
//*=======================================
//* After making sure that datasets exist
//* we can do what we are supposed to.
//* This program in pseudocode looks like this:
//* if ZGVSAM.ESDS is empty: (STEP010)
//*     copy ZGPDS.DSET(MEMB1) to ZGVSAM.ESDS (STEP020)
//*     return STEP010.RC (which is > 0)
//* else:
//*     if ZGPDS.DSET(MEMB2) doesnt exist: (STEP030)
//*         create ZGPDS.DSET(MEMB2) (STEP040)
//*         return ABEND
//*     else:
//*         delete ZGVSAM.ESDS, ZGPDS.DSET
//*         return 0
//*=======================================
//*
//* Try to print data from VSAM
//STEP010  EXEC PGM=IDCAMS
//INDD     DD DISP=SHR,DSN=&SYSUID..ZGVSAM.ESDS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
 PRINT INFILE(INDD) CHARACTER
//* Reading from empty VSAM return RC > 0
//STEPIF3 IF STEP010.RC > 0 THEN
//STEP020 EXEC PGM=IDCAMS
//INDD     DD DISP=SHR,DSN=&SYSUID..ZGPDS.DSET(MEMB1)
//OUTDD    DD DISP=OLD,DSN=&SYSUID..ZGVSAM.ESDS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
 REPRO INFILE(INDD) OUTFILE(OUTDD)
//*
//ELSE3 ELSE
//* Try to read data from ZGPDS.DSET(MEMB2)
//STEP030 EXEC PGM=IEBGENER
//SYSUT1 DD DSN=&SYSUID..ZGPDS.DSET(MEMB2),DISP=(SHR)
//SYSUT2  DD  SYSOUT=*
//SYSIN DD DUMMY
//SYSPRINT DD SYSOUT=*
//* Reading from non-existing member of PDS causes ABEND
//STEPIF4 IF STEP030.ABEND THEN
//* Write data to ZGPDS.DSET(MEMB2) from inline stream
//STEP040 EXEC PGM=IEBGENER
//SYSUT1 DD *
 ZADANIE GRUPOWE
/*
//SYSUT2 DD DSN=&SYSUID..ZGPDS.DSET(MEMB2),DISP=(SHR)
//SYSIN DD DUMMY
//SYSPRINT DD DUMMY
//ELSE4 ELSE
//* Lets delete used dataset
//* so after 3 runs there will be no garbage left from our job
//STEP050 EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN DD *,SYMBOLS=EXECSYS
 DELETE &SYSUID..ZGVSAM.ESDS
 DELETE &SYSUID..ZGPDS.DSET
/*
//ENDIF4 ENDIF
//ENDIF3 ENDIF


