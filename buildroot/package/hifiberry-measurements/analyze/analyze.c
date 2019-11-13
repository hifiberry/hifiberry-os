//
//  analyze.c
//  
//
//  Created by Joerg Schambacher on 6.11.2019
//	i2Audio GmbH
//

#include <alsa/asoundlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <signal.h>
#include <stdlib.h>
#include <math.h>
#include <limits.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>

#define NRM  "\x1B[0m"
#define RED  "\x1B[31m"
#define GRN  "\x1B[32m"
#define YEL  "\x1B[33m"
#define BLU  "\x1B[34m"
#define MAG  "\x1B[35m"
#define CYN  "\x1B[36m"
#define WHT  "\x1B[37m"

#define 	exp10(x)	pow(10.0,x)
#define 	sqr(x)		((x)*(x))
#define 	NOISEFLOOR	(1e-15)
#define 	dB(x)		(20*log10((x)+NOISEFLOOR))
#define 	idB(x)		(exp10(x/20.0))

#define printOK(...)	do{printf(GRN); printf(__VA_ARGS__); printf(NRM);}while(0);
#define printERR(...)	do{printf(RED); printf(__VA_ARGS__); printf(NRM);}while(0);

#define BIT_DEPTH   32		/* only 32 bit are supported for now */
#define MULTITONE	0
#define SWEEP		1
#define SINE		2

#define STEREO		0
#define LEFT		1
#define RIGHT		2

#define LOG_RESULTS(...) do {\
	if(log_results) fprintf(LOGFILE, __VA_ARGS__); \
	fflush(LOGFILE);\
} while (0)

char filename[256] = "\0";
char logfilename[256] = "\0";
FILE *LOGFILE;

unsigned int rate, channels, msecs, padding, mode;

double *refmag, *refpha;	/* reference FFT */
double *pcmmag, *pcmpha;	/* single recording FFT */
double *resmag, *respha;	/* summed FFT */
int *pcm;
int vbw;
unsigned fftsize;
int numoptpts = 64;

int verbose = 0;
int log_results = 0;
double fminswp = 20.0;
double fmaxswp = 20000;

void usage(char *name);
int setoptions(int argc, char *argv[]);
int fft_mono(int n,double *x,double *y);
int read_ref_file(char *filename);
int main(int argc, char *argv[]);
void reduce_samples(void);
int read_wave(char *filename, int *pcm);
unsigned get_fftsize_of_wavfile(char *filename);
 
void usage(char *name)
{
	printf("usage:\n");
	printf("%s [options] -r reference-file file1 file2 ...\n", name);
	printf("-n 	number of reduced FFT sample points \n");
	printf("-r 	reference filename\n");
	printf("-v 	verbosity level\n");
	printf("\n");
	exit(0);
}

int setoptions(int argc, char *argv[])
{
  	int c;

	printf("HiFiBerry MultiFFT Tool V0.9 (c) 2019\n");
	printf("=====================================\n");

	if (argc == 1)
		usage(argv[0]);
		
  	opterr = 0;

  	while ((c = getopt (argc, argv, "n:r:hv:")) != -1)
  		switch (c) {
  		case 'v':
  			verbose = atoi(optarg);
			break;
  		case 'n':
  			numoptpts = atoi(optarg);
			break;
  		case 'r':
  			strcpy(filename,optarg);
			break;
  		case 'h':
  		case '?':
			usage(argv[0]);
  		  	return 1;
  		default:
			usage(argv[0]);
			break;
  		}

	if (optind < argc)
		return optind;
	return 0;
}

int fft_mono(int n,double *x,double *y)
{
	unsigned m=log2(n),i,i1,j,k,i2,l,l1,l2;
	double c1,c2,tx,ty,t1,t2,u1,u2,z;
	
	i2 = n >> 1;
	j = 0;
	for (i=0;i<n-1;i++) {
	    if (i < j) {
			tx = x[i];
			ty = y[i];
			x[i] = x[j];
			y[i] = y[j];
			x[j] = tx;
			y[j] = ty;
	    }
	    k = i2;
	    while (k <= j) {
			j -= k;
			k >>= 1;
	    }
	    j += k;
	}

	c1 = -1.0;
	c2 = 0.0;
	l2 = 1;
	for (l=0;l<m;l++) {
	    l1 = l2;
	    l2 <<= 1;
	    u1 = 1.0;
	    u2 = 0.0;
	    for (j=0;j<l1;j++) {
			for (i=j;i<n;i+=l2) {
			    i1 = i + l1;
			    t1 = u1 * x[i1] - u2 * y[i1];
			    t2 = u1 * y[i1] + u2 * x[i1];
			    x[i1] = x[i] - t1;
			    y[i1] = y[i] - t2;
			    x[i] += t1;
			    y[i] += t2;
			}
			z =  u1 * c1 - u2 * c2;
			u2 = u1 * c2 + u2 * c1;
			u1 = z;
	    }
	    c2 = sqrt((1.0 - c1) / 2.0);
	    c2 = -c2;
	    c1 = sqrt((1.0 + c1) / 2.0);
	}

	for (i=0;i<n;i++) {	     
		    x[i] /= n>>1;
		    y[i] /= n>>1;
	}			     
	return 0;		     
}

int read_ref_file(char *filename)
{
	int i;
	
	read_wave(filename, pcm);

	/* do reference FFT */

	double max = 0.0, tmp;

	for (i = 0; i < fftsize; i++){
		refmag[i] = (double)pcm[i];
		refpha[i] = 0;
	}

	fft_mono(fftsize, refmag, refpha);

	for (i = 0; i < fftsize/2; i++){
		tmp = sqrt(sqr(refmag[i])+sqr(refpha[i]));
		refpha[i] = atan(refpha[i])/sqr(refmag[i]);
		refmag[i] = dB(tmp);
		if (refmag[i] > max) max = refmag[i];
	}
	for (i = 0; i < fftsize/2; i++)
		refmag[i] -= max;

#if 0
	FILE *f;
	double freq = 0.0;
	f=fopen("fftdB.csv","w+");
	for (i = 0; i < fftsize/2; i++){
		freq = i*(double)rate/(double)fftsize;
		fprintf(f, "%.2f, %.1f, %f\n", freq, refmag[i], refpha[i]); 
		}
	fclose(f);
#endif
	return 0;
}

int process_wav_file(char *filename)
{
	int i;
	static int notfirst;

	if (!notfirst) {	/* first run */
		if (verbose) printf("1st run: %s\n", filename);
		if (NULL==(pcmmag=malloc(fftsize*sizeof(double)))){
			printERR("out of memory (pcmmag)\n");
			exit(-1);
		}
		if (NULL==(pcmpha=malloc(fftsize*sizeof(double)))){
			printERR("out of memory (pcmpha)\n");
			exit(-1);
		}
	} else {
		if (verbose) printf("%i. run: %s\n", notfirst+1, filename);
	}

	/* do FFT */
	
	read_wave(filename, pcm);

	double tmp;

	for (i = 0; i < fftsize; i++){
		pcmmag[i] = (double)pcm[i];
		pcmpha[i] = 0;
	}

	fft_mono(fftsize, pcmmag, pcmpha);

	for (i = 0; i < fftsize/2; i++){
		tmp = sqrt(sqr(pcmmag[i])+sqr(pcmpha[i]));
		pcmpha[i] = atan(pcmpha[i])/sqr(pcmmag[i]);
		pcmmag[i] = tmp;
	}

	if (!notfirst) {	/* first run */
		for (i = 0; i < fftsize/2; i++) {
			resmag[i] = pcmmag[i];
			respha[i] = pcmpha[i];
		}
	} else {
		for (i = 0; i < fftsize/2; i++) {
			resmag[i] += pcmmag[i];
			respha[i] += pcmpha[i];
			resmag[i] /= 2;
			respha[i] /= 2;
		}
	}

#if 0
	FILE *f;
	double freq = 0.0;
	char buffer[32];
	snprintf(buffer, 32, "fftdB_rec%i.csv", notfirst+1);
	f=fopen(buffer,"w+");
	for (i = 0; i < fftsize/2; i++){
		freq = i*(double)rate/(double)fftsize;
		fprintf(f, "%.2f, %.1f, %f\n", freq, dB(pcmmag[i]), pcmpha[i] * 180 / M_PI); 
		}
	fclose(f);
#endif
	notfirst++;
	return 0;
}


int main(int argc, char *argv[]) {

	int start, i;
	unsigned max;

	start = setoptions(argc, argv);
	
	if (!strlen(filename)) {
		printf("Error: reference file not given!\n");
		usage(argv[0]);
		exit(0);
	}
	
	max = get_fftsize_of_wavfile(filename); /* reference file */

	for (i = start; i < argc; i++) {	/* test recordings */
		fftsize = get_fftsize_of_wavfile(argv[i]);
		if (fftsize > max)
			max = fftsize;
	}

	fftsize = max;
	printf("allocating %i frames\n", fftsize);

	/* memory for reference FFT */
	if (NULL == (refmag = malloc(fftsize * sizeof(double)))){
		printERR("out of memory (refmag)\n");
		exit(-1);
	}

	if (NULL == (refpha = malloc(fftsize * sizeof(double)))){
		printERR("out of memory (refpha)\n");
		exit(-1);
	}
	
	/* memory for reading files */
	if(NULL == (pcm = malloc(fftsize * sizeof(int)))){
		printERR("out of memory (pcmmag)!\n");
		exit(-1);
	}
	
	/* memory for recording FFT(s) */
	if(NULL == (pcmmag = malloc(fftsize * sizeof(double)))){
		printERR("out of memory (pcmmag)!\n");
		exit(-1);
	}
	
	if(NULL == (pcmpha = malloc(fftsize * sizeof(double)))){
		printERR("out of memory (pcmpha)!\n");
		exit(-1);
	}
	
	/* memory for summed FFT */
	if(NULL == (resmag = malloc(fftsize * sizeof(double)))){
		printERR("out of memory (resmag)!\n");
		exit(-1);
	}
	bzero(resmag, fftsize);
	
	if(NULL == (respha = malloc(fftsize * sizeof(double)))){
		printERR("out of memory (respha)!\n");
		exit(-1);
	}
	bzero(respha, fftsize);
	
	read_ref_file(filename);

	while(0 == access(argv[start], 0)) {
		printf("processing %s\n", argv[start]);
		process_wav_file(argv[start]);
		start++;
	}
	
	reduce_samples();
	
	printf("done.\n");
	return 0;
}

void reduce_samples(void)
{
	int i, j, cnt;
	double *res, *fr, *pha;

	if(NULL ==(res = malloc(numoptpts * sizeof(double)))){
		printERR("out of memory!\n");
		return;
	}
	if(NULL ==(pha = malloc(numoptpts * sizeof(double)))){
		printERR("out of memory!\n");
		return;
	}
	if(NULL ==(fr = malloc(numoptpts * sizeof(double)))){
		printERR("out of memory!\n");
		return;
	}

	double bit_scale = powf(2,31);
	for(i = 0; i < fftsize/2; i++) {
		resmag[i] = dB(resmag[i] / bit_scale);
		resmag[i] -= refmag[i];
		respha[i] -= refpha[i];
	}


	double fend;
	double x = pow(fmaxswp / fminswp, 1.0/(double)numoptpts);
	double vbw = (double)rate/((double)fftsize);
//	printf("fftsize %i, VBW %6.1f\n", fftsize, vbw);
	for(i = 0; i < numoptpts; i++){
		fr[i] = fminswp * pow(x, i);
		fend = fminswp * pow(x, i+1);
		if (verbose > 0) printf("averaging from %f.2 to %.2f\n", fr[i], fend);
		res[i] = 0.0;
		pha[i] = 0.0;
		cnt = 0;
		j = (int) (fr[i]/vbw + 0.5);
		while (j * vbw < fend && j < fftsize / 2) {
			res[i] += resmag[j];
			pha[i] += respha[j];
			j++;
			cnt++;
		}
		res[i] /= cnt;
		pha[i] /= cnt / 180.0 * M_PI;
		fr[i] = (fend - fr[i]) / log( fend / fr[i]);	/* take the log average */
	}
	FILE *f;
	f=fopen("fftdB_vbw.csv","w+");
	for (i = 0; i < numoptpts; i++){
		fprintf(f, "%f, %.2f, %.5f\n", fr[i], res[i], pha[i]); 
		}
	fclose(f);
}

int read_wave(char *filename, int *pcm)
{
int fd, tmp, len;

struct struct_wavheader{
	char riff[4];
	unsigned filesize;
	char wave[4];
	char fmt[4];
	int fmtlen;
	short fmttype;
	short channels;
	int samplerate;
	int bytespersec;
	short framesize;
	short bitspersample;
	char data[4];
	unsigned datasize;
	}wavheader;

	if (-1 == (fd=open(filename,O_RDONLY))) {
		printf("open error %s (%i)\n",filename,fd);
		exit(-1);
	}
	if ((tmp = read(fd, &wavheader, sizeof(wavheader))) != sizeof(wavheader)) {
		printERR("read error %s (%i bytes read)\n",filename,tmp);
		exit(-1);
	}
	if (verbose > 1) {
		printf("file info: riff %4s wave %4s\n",
			wavheader.riff, wavheader.wave);
		printf("file info: %i channels %ibit @ %isps\n",
			wavheader.channels, wavheader.bitspersample, 
			wavheader.samplerate);
		printf("file info: %i bytes/sec %i framesize @ %i fmtlen\n",
			wavheader.bytespersec, wavheader.framesize, 
			wavheader.fmtlen);
		printf("filesize %i bytes\n",wavheader.filesize);
		printf("datasize %i bytes\n",wavheader.datasize);
	}
	if (wavheader.channels != 1 || wavheader.bitspersample != 32) {
		printERR("WAV file has wrong format!\nOnly 1 channel 32bit supported.\n");
		exit(-1);
	}

	rate = wavheader.samplerate;
	len = wavheader.filesize + 8 - 44;

	bzero(pcm, fftsize);
	
	if ((tmp = read(fd, pcm, len)) != len) {
		printERR("read error %i bytes read instead of %i\n",tmp,len);
		exit(-1);
	}
	if (verbose > 1) {
		printOK("%i bytes of data read.\n", tmp);
		printOK("%i frames = %usecs\n", tmp/4,
					tmp/(4*wavheader.samplerate));
	}
	close(fd);
	return 0;
}

unsigned get_fftsize_of_wavfile(char *filename)
{
int fd, tmp, len;

struct struct_wavheader{
	char riff[4];
	unsigned filesize;
	char wave[4];
	char fmt[4];
	int fmtlen;
	short fmttype;
	short channels;
	int samplerate;
	int bytespersec;
	short framesize;
	short bitspersample;
	char data[4];
	unsigned datasize;
	}wavheader;

	if (access(filename, 0)) {
		printERR("file not found: %s\n",filename);
		return 0;
	}

	if (-1 == (fd=open(filename,O_RDONLY))) {
		printERR("open error %s (%i)\n",filename,fd);
		return 0;
	}
	if ((tmp = read(fd, &wavheader, sizeof(wavheader))) != sizeof(wavheader)) {
		printERR("read error %s (%i bytes read)\n",filename,tmp);
		return 0;
	}

	if (wavheader.channels != 1 || wavheader.bitspersample != 32) {
		printERR("WAV file has wrong format!\nOnly 1 channel 32bit supported.\n");
		return 0;
	}

	len = wavheader.filesize + 8 - 44;

	if (verbose > 1)
		printf("%i frames in file %s\n", len / 4, filename);

	return (unsigned)exp2(ceil(log2(len / 4)));
}
