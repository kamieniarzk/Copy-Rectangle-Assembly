#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <math.h>



typedef struct
{
	int width, height;
	unsigned char* pImg;
	int cX, cY;
	int col;
} imgInfo;

typedef struct
{
	int left, top, right, bottom;
} Rect;

typedef struct
{
	int x, y;
} Point;

typedef struct
{
	unsigned short bfType; 
	unsigned long  bfSize; 
	unsigned short bfReserved1; 
	unsigned short bfReserved2; 
	unsigned long  bfOffBits; 
	unsigned long  biSize; 
	long  biWidth; 
	long  biHeight; 
	short biPlanes; 
	short biBitCount; 
	unsigned long  biCompression; 
	unsigned long  biSizeImage; 
	long biXPelsPerMeter; 
	long biYPelsPerMeter; 
	unsigned long  biClrUsed; 
	unsigned long  biClrImportant;
	unsigned long  RGBQuad_0;
	unsigned long  RGBQuad_1;
} bmpHdr;


//ALL FUNCTIONS HAVE ARGUMENTS FROM STACK, SO THEY CAN BE CALLED FROM C AS WELL
extern void set_pixel(imgInfo* pInfo, int x, int y);
extern int load_pixel(imgInfo* pInfo, int x, int y);
extern void set_color(imgInfo* pInfo, int col);
extern int copy_rect(imgInfo* pImg, Rect pSrc, Point pDst);



void* freeResources(FILE* pFile, void* pFirst, void* pSnd)
{
	if (pFile != 0)
		fclose(pFile);
	if (pFirst != 0)
		free(pFirst);
	if (pSnd !=0)
		free(pSnd);
	return 0;
}

imgInfo* readBMP(const char* fname) 
/*MODIFIED, BECAUSE IT CAUSED SEGMENTATION FAULT IF THE HEADER CHECK FAILED
  ALSO TO HAVE (0,0) IN THE BOTTOM LEFT CORNER */
{
	imgInfo* pInfo = 0;
	FILE* fbmp = 0;
	bmpHdr bmpHead;
	int lineBytes, y;
	unsigned long imageSize = 0;
	unsigned char* ptr;

	pInfo = 0;
	fbmp = fopen(fname, "rb");
	if (fbmp == 0)
	{
		printf("\nERROR WHILE READING FILE\n");
		return NULL;
	}

	fread((void *) &bmpHead, sizeof(bmpHead), 1, fbmp);
	//// some checks
	//if (bmpHead.bfType != 0x4D42 || bmpHead.biPlanes != 1 ||
		//bmpHead.biBitCount != 1 || bmpHead.biClrUsed != 2 ||
		//(pInfo = (imgInfo *) malloc(sizeof(imgInfo))) == 0)
		//return NULL;
	pInfo = (imgInfo *) malloc(sizeof(imgInfo));
	if(!pInfo) return NULL;
	
	pInfo->width = bmpHead.biWidth;
	pInfo->height = bmpHead.biHeight;
	imageSize = (((pInfo->width + 31) >> 5) << 2) * pInfo->height;
	pInfo->pImg = (unsigned char*) malloc(imageSize);
	if(!pInfo->pImg) return NULL;
	//if ((pInfo->pImg = (unsigned char*) malloc(imageSize)) == 0)
		//return (imgInfo*) freeResources(fbmp, pInfo->pImg, pInfo);

	// process height (it can be negative)
	ptr = pInfo->pImg;
	lineBytes = ((pInfo->width + 31) >> 5) << 2; // line size in bytes
	//if (pInfo->height > 0)
	//{
		//// "upside down", bottom of the image first
		//ptr += lineBytes * (pInfo->height - 1);
		//lineBytes = -lineBytes;
	//}
	//else
		//pInfo->height = -pInfo->height;

	// reading image
	// moving to the proper position in the file
	if (fseek(fbmp, bmpHead.bfOffBits, SEEK_SET) != 0)
		return (imgInfo*) freeResources(fbmp, pInfo->pImg, pInfo);

	for (y=0; y<pInfo->height; ++y)
	{
		fread(ptr, 1, abs(lineBytes), fbmp);
		ptr += lineBytes;
	}
	fclose(fbmp);
	return pInfo;
}


int saveBMP(const imgInfo* pInfo, const char* fname)
{
	if(!pInfo)
	{
		printf("\nERROR WHILE SAVING FILE\n");
		return 0;
	}
	
	int lineBytes = ((pInfo->width + 31) >> 5)<<2;
	bmpHdr bmpHead = 
	{
	0x4D42,				// unsigned short bfType; 
	sizeof(bmpHdr),		// unsigned long  bfSize; 
	0, 0,				// unsigned short bfReserved1, bfReserved2; 
	sizeof(bmpHdr),		// unsigned long  bfOffBits; 
	40,					// unsigned long  biSize; 
	pInfo->width,		// long  biWidth; 
	pInfo->height,		// long  biHeight; 
	1,					// short biPlanes; 
	1,					// short biBitCount; 
	0,					// unsigned long  biCompression; 
	lineBytes * pInfo->height,	// unsigned long  biSizeImage; 
	11811,				// long biXPelsPerMeter; = 300 dpi
	11811,				// long biYPelsPerMeter; 
	2,					// unsigned long  biClrUsed; 
	0,					// unsigned long  biClrImportant;
	0x00000000,			// unsigned long  RGBQuad_0;
	0x00FFFFFF			// unsigned long  RGBQuad_1;
	};

	FILE * fbmp;
	unsigned char *ptr;
	int y;

	if ((fbmp = fopen(fname, "wb")) == 0)
		return -1;
	if (fwrite(&bmpHead, sizeof(bmpHdr), 1, fbmp) != 1)
	{
		fclose(fbmp);
		return -2;
	}

	ptr = pInfo->pImg;// + lineBytes * (pInfo->height - 1);
	for (y=0; y < pInfo->height; ++y, ptr += lineBytes)
		if (fwrite(ptr, sizeof(unsigned char), lineBytes, fbmp) != lineBytes)
		{
			fclose(fbmp);
			return -3;
		}
	fclose(fbmp);
	return 0;
}

/****************************************************************************************/
imgInfo* InitScreen (int w, int h)
{
	imgInfo *pImg;
	if ( (pImg = (imgInfo *) malloc(sizeof(imgInfo))) == 0)
		return 0;
	pImg->height = h;
	pImg->width = w;
	pImg->pImg = (unsigned char*) malloc((((w + 31) >> 5) << 2) * h);
	if (pImg->pImg == 0)
	{
		free(pImg);
		return 0;
	}
	memset(pImg->pImg, 0xFF, (((w + 31) >> 5) << 2) * h);
	pImg->cX = 0;
	pImg->cY = 0;
	pImg->col = 0;
	return pImg;
}

void FreeScreen(imgInfo* pInfo)
{
	if (pInfo && pInfo->pImg)
		free(pInfo->pImg);
	if (pInfo)
		free(pInfo);
}

int main()
{
	//(0,0) is located in the botttom left corner of the picture
	Rect r = {230, 280, 280, 230};	//left, top, right, bottom
	Point pt = {235, 280};			//x, y
	imgInfo *pInfo;
	if (sizeof(bmpHdr) != 62)
	{
		printf("Change compilation options so as bmpHdr struct size is 62 bytes.\n");
		return 1;
	}
	if ((pInfo = InitScreen (512, 512)) == 0)
		return 0;
	pInfo = readBMP("start.bmp");
	
	if(pInfo) 
		copy_rect(pInfo, r, pt);
	
	saveBMP(pInfo, "result.bmp");
	FreeScreen(pInfo);
	return 0;
}

