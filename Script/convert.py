import glob as gl
import cv2
import numpy
import os
import datetime
import sys
import getopt
from PIL import Image
from ffmpy import FFmpeg

def convertImage(original_img):
	width, height = original_img.size

	# 生成一张大小和原图一样的纯白的图片，并且提取出R G B
	alpha_img = Image.new("RGBA",original_img.size,(255, 255, 255, 255))
	alpha_bands = alpha_img.split()
	alpha_rIm = alpha_bands[0]
	alpha_gIm = alpha_bands[1]
	alpha_bIm = alpha_bands[2]

	# 提取出原始图片的Alpha通道的值
	original_bands = original_img.split()
	original_aIm = original_bands[3]
	# 合并纯白图片的RGB值以及原始图片的Alpha值
	alpha_img = Image.merge("RGBA", (alpha_rIm, alpha_gIm, alpha_bIm, original_aIm))

	# 生成一张纯黑的图片，并且把上面的图片贴上去，得到一张最终可以使用明度（黑）来表示原始图片透明度的图片
	alpha_img_bg = Image.new("RGBA",(width, height),(0, 0, 0, 255))
	alpha_img_bg.paste(alpha_img, (0, 0), alpha_img)

	# 生成一张二倍大小的图片，左边是原图，右边是透明度信息
	result_image = Image.new("RGBA",(width * 2, height), (0, 0, 0, 255))
	result_image.paste(original_img, (0, 0), original_img)
	result_image.paste(alpha_img_bg, (width, 0))
	return result_image

def deleteFile(filePath):
	if os.path.exists(filePath):
		os.remove(filePath)

def openImage(image_path):
	image = Image.open(image_path)
	width, height = image.size
	maxWidth = 500.0
	if width <= maxWidth:
		return image
	else:
		scale = maxWidth / width
		width = int(width * scale)
		height = int(height * scale)
		image = image.resize((width, height))
		return image


def generalMP4(filePath):
	paths = gl.glob(os.path.join(filePath, '*.png'))
	paths.sort()
	if len(paths) == 0:
		print("该文件夹下面没有图片哦!")
		sys.exit()
	conerted_images = []
	i = 0
	for image_path in paths:
		conerted_image = convertImage(openImage(image_path))
		conerted_images.append(conerted_image)

	fps = 24
	size = conerted_images[0].size
	fourcc = cv2.VideoWriter_fourcc(*'mp4v')
	oput_tmp_path = os.path.join(filePath, 'tmp.mp4')
	deleteFile(oput_tmp_path)
	videoWriter = cv2.VideoWriter(oput_tmp_path, fourcc, fps, size)
	for conerted_image in conerted_images:
		pil_image = conerted_image.convert('RGB')
		open_cv_image = cv2.cvtColor(numpy.asarray(pil_image),cv2.COLOR_RGB2BGR)	
		i = i + 1
		videoWriter.write(open_cv_image)
	videoWriter.release()
	result_path = os.path.join(filePath, 'result.mp4')
	deleteFile(result_path)
	ff = FFmpeg(inputs = {oput_tmp_path: None},
                outputs = {result_path: '-c:v h264'})
	ff.run()
	deleteFile(oput_tmp_path)

opts, args = getopt.getopt(sys.argv[1:], "ag")
if len(args) == 0:
	print("Error：缺少帧序列文件夹目录，请在空格后面带上文件夹目录")
	sys.exit()
target_file_path = args[0]
if os.path.exists(target_file_path) == False:
	print("文件夹不存在！！！")
	sys.exit()

print("正在处理。。。")
print("目标路径：" + target_file_path)
starttime = datetime.datetime.now()
generalMP4(target_file_path)
endtime = datetime.datetime.now()
print("处理完成，耗时：" + str((endtime - starttime).seconds) + "秒")