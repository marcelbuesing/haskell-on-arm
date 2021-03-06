help:
	@echo
	@echo "make create-armhf-debian-jessie-image  -- base OS docker image"
	@echo "make publish-armhf-debian-jessie-image -- publishes ^^ to registry"
	@echo
	@echo "make create-haskell-platform-armhf-debian-jessie  -- adds packages required to run ghc to base"
	@echo "make publish-haskell-platform-armhf-debian-jessie -- publishes ^^ to registry"
	@echo


# 3.5.2 works well with ghc-7.10.3
LLVM35_VERSION=3.5.2
LLVM35_TXZ=clang+llvm-$(LLVM35_VERSION)-armv7a-linux-gnueabihf.tar.xz
# 3.7.1 is needed for ghc-8
LLVM37_VERSION=3.7.1
LLVM37_TXZ=clang+llvm-$(LLVM37_VERSION)-armv7a-linux-gnueabihf.tar.xz

# Docker image tag, date based
TAG=$(shell date +%Y%m%d)


# Has everything needed to run stack/ghc but not the actual binaries.
# It's easier to manage them in a local directory and mount as a volume into docker.
# Builds a flattened image with intermediate layers merged.
create-haskell-platform-armhf-debian-jessie: \
	docker/haskell-platform-armhf-debian-jessie/$(LLVM35_TXZ) \
	docker/haskell-platform-armhf-debian-jessie/$(LLVM37_TXZ)

	cd docker/haskell-platform-armhf-debian-jessie/ && docker build -t haskell-platform-armhf-debian-jessie:latest .
	ID=`docker run -d haskell-platform-armhf-debian-jessie:latest /bin/bash` ; \
		 docker export $$ID | docker import - andreyk0/haskell-platform-armhf-debian-jessie:$(TAG) ; \
		 docker rm $$ID ; \
	   docker rmi haskell-platform-armhf-debian-jessie:latest

# Pushes image to docker registry.
publish-haskell-platform-armhf-debian-jessie:
	docker push andreyk0/haskell-platform-armhf-debian-jessie:$(TAG)

# Download version known to work with GHC 7.10.x
docker/haskell-platform-armhf-debian-jessie/$(LLVM35_TXZ):
	wget -O $@ http://llvm.org/releases/$(LLVM35_VERSION)/$(LLVM35_TXZ)

# Download version known to work with GHC 8.0
docker/haskell-platform-armhf-debian-jessie/$(LLVM37_TXZ):
	wget -O $@ http://llvm.org/releases/$(LLVM37_VERSION)/$(LLVM37_TXZ)

# Creates a base OS docker image from the SD card images.
create-armhf-debian-jessie-image: \
	docker/armhf-debian-jessie/jessie.tgz \
	docker/armhf-debian-jessie/qemu-arm-static

	cd docker/armhf-debian-jessie && docker build -t andreyk0/armhf-debian-jessie:$(TAG) .


publish-armhf-debian-jessie-image:
	docker push andreyk0/armhf-debian-jessie:$(TAG)


# You need qemu-user-static to be installed.
docker/armhf-debian-jessie/qemu-arm-static: /usr/bin/qemu-arm-static
	cp -av $< $@


# Assumes you have these .img files from the SD card, root and boot partitions.
# E.g. as root: cat /dev/sdc1 > root.img
docker/armhf-debian-jessie/jessie.tgz: root.img boot.img
	mkdir -pv /tmp/sdcard
	sudo mount -o loop root.img /tmp/sdcard
	sudo mount -o loop boot.img /tmp/sdcard/boot
	sudo tar czvf `pwd`/$@ -C /tmp/sdcard/ .
	sudo chown `id -u`:`id -g` $@
	sudo umount /tmp/sdcard/boot
	sudo umount /tmp/sdcard
	sudo rmdir /tmp/sdcard
