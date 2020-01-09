HPC LINPACK benchmark

---

# 介绍

LINPACK （Linear system package）即线性系统软件包，该工具

> 通过在高性能计算机上用**高斯消元法**求解 N 元一次稠密线性代数方程组的测试，评价高性能计算机的**浮点**性能。

HPL（High Performance Linpack）是针对现代**并行计算集群**的测试工具。

>  用户不修改测试程序,通过调节问题规模大小 N（矩阵大小）、进程数等测试参数,使用各种优化方法来执行该测试程序,以获取最佳的性能。



## 浮点计算能力

> 浮点计算能力=计算量(2/3 * N^3-2*N^2)/计算时间T

N为问题规模。当求解问题规模为 N 时，浮点运算次数为(2/3 * N^3-2*N^2)。
测试结果以浮点运算每秒（Flops）表示。

浮点计算峰值衡量计算机性能的一个重要指标，它是指计算机每秒钟能完成的浮点计算操作数：

- 理论浮点峰值（Rpeak）

  理论上能达到的每秒钟能完成的最大浮点计算次数

  决定因素：CPU 本身规格和 CPU 的数量决定
  >Rpeak=CPU 主频(标准频率)× CPU 每个时钟周期执行浮点运算的次数×系
  >统中 CPU 的总核数

- 实测浮点峰值（Rmax）

  Linpack测得的实际值

通常情况下，理论浮点峰值是基于 CPU 的标准频率计算的。如果 CPU超频后使得实际运行的频率高于标准频率，实测浮点峰值(Rmax)可能高于理论浮点峰值(Rpeak)。

### 集群计算能力

> 单节点理论计算能力 = 单节点中 CPU 数量 * 单颗 CPU 核数 * CPU 的标称
> 主频 * 每周期执行的指令数

> 集群理论计算能力 = 集群节点数 * 单节点的理论计算能力

# 准备

## BIOS 配置调优

将 BIOS 配置为性能最优模式，常用配置项如 ：

- 电源策略（Power Policy）或CPU frequency：高性能之类的模式
  - intel CPU C 状态：关闭
- 空闲低功耗模式（CPU C-State）：关闭
- 睿频（Turbo Boost或Turbo Core）：启用
- 超线程（Hyper-Threading）：关闭

## 集群配置

如果在集群中测试，需要：

- 网卡驱动、IP等配置完成
- 各个节点ssh密钥认证
- 集群共享目录（用以安装hpl，或者在所有节点上安装到相同路径亦可）

## HPL安装

HPL软件包需要再配备了MPI环境选的系统中才能运行，还需要底层有线性代数子程序包BLAS的支持（或者有另一种向量信号图像处理库VSIPL也可）

编译HPL需要一些常见的基础的工具支持，如gcc、gcc-c++、gcc-gfortran等，编译中如有缺失根据提示安装即可。

HPL需要有线性代数子程序包BLAS（参看后文俘虏中关于blas和blas各种实现的介绍）的支持，或者向量信号图像处理库VSIPL。

编译常用组合选择：

- HPL + [Intel® Parallel Studio XE](https://software.intel.com/en-us/intel-parallel-studio-xe)（intel编译器 + intel mkl + intel-mpi）

  intel套件包含了数学库(mkl)、各种编译器(如icc、gcc)和intel mpi。

  此外，安装Intel套件后，在其安装目录下的`mkl/benchmarks/linpack`及`mkl/benchmarks/mp_linpack`文件夹下有编译好的linpack及测试脚本，可直接使用；或者也可直接下载[intel的测试工具](https://software.intel.com/en-us/articles/intel-mkl-benchmarks-suite)。

- HPL + ACML + GNU编译器 + 开源mpi

  ACML由AMD推出，用于AMD的cpu。

- HPL + GNU编译器+ blas或lapack等数学库 + 开源mpi

  - 数学库：blas/lapack  等（参看后文附录中关于blas、lapack等数学库的介绍）

    如从包管理中安装，在debian/rhel系上均需要安装devel/dev版本。

  - mpi：mpich或openmpi

    提示：mpich和openmpi安装后可能需要自行添加`PATH`和`LD_LIBRARAY_PATH`。

以上也可以混合实现，如使用openmpi+[mkl](https://software.intel.com/en-us/mkl/choose-download)+gcc等开源编译器。

### HPL-cpu

1. 下载[hpl](http://www.netlib.org/benchmark/hpl/)，解压后进入hpl目录。

   如果编译器，mpi、blas已经安装完成且加入环境变量，直接执行`configure`，然后执行`make`编译，将在testing目录下生成xhpl。

   或者按照以下方式手动配置编译参数。

2. 复制子目录setup下Make文件（如setup/Make.Linux_Intel64）到当前目录，根据此次测试使用的[HPL相关工具](#HPL相关工具)的安装情况，对hpl的Make编译文件进行修改，主要修改的变量有:

   - ARCH:  必须与文件名 `Make.<arch>`中的`<arch>`一致

   - TOPdir: 指明 hpl 程序所在的目录

   - MPdir:  MPI 所在的目录

   - MPlib:  MPI 库文件

   - LAdir:  BLAS 库或 VSIPL 库所在的目录

   - LAinc、LAlib: BLAS 库或 VSIPL 库头文件、库文件

   - HPL_OPTS: 包含采用什么库、是否打印详细的时间、L广播参数等，若

     - 采用 FLBAS 库则置为空
     - 采用 CBLAS 库为`-DHPL_CALL_CBLAS`
     - 采用 VSIPL  为`-DHPL_CALL_VSIPL`

     `-DHPL_DETAILED_TIMING`为打印每一步所需的时间，默认不打印

     `-DHPL_COPY_L`为在  L 广播之前拷贝 L，默认不拷贝

   - CC:  C 语言编译器

   - CCFLAGS: C 编译选项

   - LINKER: Fortran 77 编译器

   - LINKFLAGS: Fortran 77 编译选项(Fortran 77 语言只有在采用 Fortran 库时才需要)

   

   示例1：使用intel套件编译用于intel x86_64 CPU上测试的HPL。

   复制`setup/Make.Linux_Intel64`到hpl源码根目录下，参考以下内容修改Make.Linux_Intel64文件：

   ```shell
   #TOPdir修改为当前目录（pwd）
   TOPdir       = /root/hpl-2.3
   #注意提前检查`$I_MPI_ROOT`等变量是否正确，如不正确应参看Intel parallel studio相关文档配置
   #或者直接指定绝对路径
   #MPI
   MPdir        = $(I_MPI_ROOT)
   MPinc        = -I$(MPdir)/intel64/include
   MPlib        = $(MPdir)/intel64/lib/release/libmpi.so
   #MKL
   LAdir        = $(MKLROOT)
   LAinc        = -I$(LAdir)/include
   LAlib        = -L$(LAdir)/lib/intel64 \
                  -Wl,--start-group \
                  $(LAdir)/lib/intel64/libmkl_intel_lp64.a \
                  $(LAdir)/lib/intel64/libmkl_intel_thread.a \
                  $(LAdir)/lib/intel64/libmkl_core.a \
                  -Wl,--end-group -lpthread -ldl
   #C compiler
   CC      = icc
   #OMP_DEFS = -qopenmp
   ```

   

   示例2：使用GNU编译器+openblas+mpich（均从包管理安装）编译用于aarch64 CPU上测试的HPL。

   复制`setup/Make.UNKNOWN Make`到hpl源码根目录下改名为`Make.aarch64`（名字随意），参考以下内容修改该文件：

   ```shell
   ARCH         = aarch64
   TOPdir       = $(HOME)/hpl-2.3
   #以centos为例，mpich安装后位于/usr/lib64/mpich
   #如果自行编译，则需要根据具体情况修改
   MPdir        = /usr/lib64/mpich
   #如果非包管理安装mpich，该include目录应该位于mpich的安装目录下
   MPinc        = -I /usr/include
   MPlib        = $(MPdir)/lib/libmpich.a
   #如果非包管理安装blas/lapack或其他数学库，则需要自行指定
   LAdir        = /usr/lib64
   LAlib        =  /usr/lib64  #同上
   ```

3. 编译安装：`make arch=xxx`（arch是Make.xxx中的xxx）

   编译生成xhpl可执行文件及HPL.dat，位于bin目录下名字和arch值相同的文件夹中。

### HPL-GPU

上文所述安装的hpl为cpu测试所用，测试GPU（本文所述为Nvidia的GPU）有所不同。

除了前文所述要求的mpi、数学库等工具外，还需要安装配置好以下工具：

- NVIDIA driver

  run文件版本nvidia驱动的安装

  ```shell
  #备份原启动时的初始化系统文件镜像
  cp /boot/initramfs-$(uname -r).img boot/initramfs-$(uname -r).img.bak
  #dracut -v /boot/initramfs-$(uname -r).img $(uname -r)
  #移除nouveau驱动模块
  rmod nouveau
  #如果当前已经开启图形界面，需要切换至文本界面
  systemctl isolate multi-user.target
      
  chmod +x NVIDIA*.run
  kernelVer=`uname -r` #内核版本
  #使用参数--no-opengl-files以禁止安装驱动自带的opengl 避免与已安装的opengl冲突
  #未安装kernel-devel需要指定--kernel-source-path
  #--ui=none --no-questions --accept-license自动接受协议
  ./NVIDIA*.run --kernel-source-path=/usr/src/kernels/$kernelVer -k $kernelVer --no-opengl-files --ui=none --no-questions --accept-license
  
  #卸载nvidia驱动 nvidia-uninstall
  ```

- CUDA

  run文件版本cuda安装

  ```shell
  chmod +x ./cuda*.run
  #安装时--slient静默安装
  #但是该模式下默认应用所有选项 指定--toolkit后将值安装cuda不会安装其附带的驱动
  ./cuda*.run --silent --toolkit --verbose #--verbose将打印所有日志信息
  
  #环境变量
  echo '
  export PATH=/usr/local/cuda/bin:$PATH
  export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
  ' > /etc/profile.d/cuda.sh
  source /etc/profile.d/cuda.sh
  ```

- [cuda-accelerated-linpack](https://developer.nvidia.com/rdp/assets/cuda-accelerated-linpack-linux64)  nvidia 显卡性能测试专用hpl版本（代替上文所述的hpl）

  解压后进入目录，编辑Make.CUDA文件，修改相关参数（参看上文）。

  以使用intel 2019套件为例，需要修改以下几行：

  ```shell
  #TOPdir修改为当前目录（pwd）
  TOPdir       = /root/hpl-2.0_FERMI_v15
  #MPI
  MPdir        = $(I_MPI_ROOT)
  MPinc        = -I$(MPdir)/intel64/include
  MPlib        = $(MPdir)/intel64/lib/release/libmpi.so
  #MKL
  LAdir        = $(MKLROOT)
  LAinc        = -I$(LAdir)/include
  #C compiler
  CC      = icc
  ```
  编译完成后在bin/CUDA目录下，根据具体情况修改其中的run_linpack脚本，使用该脚本进行测试，注意：

  - 如果要移走该目另下的文件到其他目录使用，需要连带复制hpl文件夹下的src目录，run_linpack脚本执行时会用到其中的库文件。
  - 测试GPU时，根据情况为每个GPU分配一定数量的CPU，修改run_linpack中的CPU_CORES_PER_GPU的值，不一定要将所有cpu都分给GPU，CPU数量过多可能反而拖累GPU测试的峰值。
  - 进行GPU测试，HPL.dat装的P和Q的值应当以GPU数量为标准。
## HPL测试

在集群测试中，一般将将测试程序xhpl及HPL.dat等文件放置到集群共享目录中。

在testing目录的子目录中有HPL.dat样本，在HPL.dat文件所在目录下执行xhpl程序即可。

```shell
xhpl #仅单cpu测试（P Q均为1）
mpirun –n <N> xhpl    #N为进程数 (PxQ<=此处的N)
mpirun -f <nodes file> -np <N> xhpl  #多节点并行
```

nodes file文件中每行为一个节点的地址（IP或hostname），如：

> 192.168.1.1
>
> 192.168.1.2

初始的HPL.dat文件无法满足需求，需要对其进行修改。



# 附

## 测试配置文件HPL.dat

输入文件HPL.dat配置参考：

- [HPL计算器](http://hpl-calculator.sourceforge.net/)

- [HPL-dat生成工具](http://www.advancedclustering.com/act-kb/tune-hpl-dat-file/)

  填入节点数、每个节点的处理器核数、每个节点的内存大小和Block  Size  (NB—数据分配和计算粒度，代表性的良好块规模是32到256个间隔。)。

其中以下几个参数是HPL.dat文件中最重要的：

- problem sizes (matrix dimension N) 

  - of problems(N) 行
  - Ns 行

  of problems设置测试问题的组数，Ns行根据of problems规定设置相应多个值。

  这两行设置求解问题规模，规模越大浮点处理性能越高，但测试时占用内存也更大，一般以内存的80%（为其他程序预留开销，具体根据情况分析）；在集群测试中，内存为所有测试的节点的总内存。

  公式：`N*N*8=内存容量*80%`

  例如内存256G（换算成kb）：  `256×1024×1024×0.8=N*N*8`  。则N=16384，如果of problems行填写3，则Ns行就可以填写三次16384。

  > 1
  >
  > 16384

  

- block size NB

  - of NBs 行
  - NBs 行

  为提高整体性能，HPL采用分块矩阵的算法，of NBs行表示要设置几组分块矩阵，NBs根据ofNBs规定数设置相应多个值，NBs取值和软硬件许多因素密切相关，根据具体测试不断调节。

  NB×8一般是CPU L2 Cache line(单位kb）的倍数，例如1024k/8=192

  一般通过单节点或单CPU测试得到较好的NB值，选择3个左右较好的NBs值，再扩大规模验证这些选择。

  > 2
  >
  > 128 192

  

- PMAP process mapping

  按列Column（值为1）适用于节点数较多且单节点处理器较少的情况，

  按行Row排列（值为0）适用于节点数较少且每个节点内CPU数较多的情况。

  

- process grid (P x Q) 

  - of process grids (P x Q) 行
  - P 行
  - Q 行

  

  这三行和CPU核心数量有关。

  of process grids 表示P行和Q要使用几组网格，该行数字为多少，则P行和Q行就要各自写相应数量的数值。

  其中`P×Q=系统CPU Process数`（关闭超线程情况下即为cpu核心数），`P<=Q`，P 的值尽量比Q取小一点；`P=2^n`，即P取值为2的幂（HPL中L分解 的列向通信采用二元交换法( Binary Exchange)，当列向处理器个数P为2 的幂时，性能最优。

  例如2CPU×8cores=16cores的情况下，选择P=2，Q=8，比P和Q均为4好。如果of process grids行写3，则 P行和Q行各写3个数字，每两个上下对应的数字的值的乘积为16，例如

  > 3        #of process grids
  >
  > 1    2  4  #Ps
  >
  > 16  8  4  #Ns

  

「10节点，每节点10核心+96G内存，块大小为192」的HPL.dat文件示例：

```shell
# 以下两行 该文件的注释说明
HPLinpack benchmark input file
Innovative Computing Laboratory, University of Tennessee

# 以下两行 输出文件
HPL.out      output file name (if any) 
6            device out (6=stdout,7=stderr,file)  #6标准输出 7标准错误输出 其他值表示输出到指定文件（这里的文件名为out）

# 以下两行 求解矩阵规模的大小
2            # of problems sizes (N)   计算的组数
16384 16384        Ns  #  每组规模
 
# 以下两行 求解矩阵分块的大小
4            # of NBs 矩阵分块大小，分块矩阵的数量
1 2 3 4        NBs  #每种分块的具体值 参数为块大小，是将问题规模划分为块的基本单元

# 以下一行 阵列处理方式 （按列的排列方式还是按行的排列方式）
0            PMAP process mapping (0=Row-,1=Column-major)

#以下三行 二维处理器网格 PxQ=系统CPU process数  其中 P<=Q  且P=2^n较优
3            # of process grids (P x Q)  使用几组网格
1   2  4         Ps   #P 和 Q 取决于物理互连网络的情况 尽量相差不大 Q 略大于 P
16 8  4        Qs   #

# 以下一行 余数的阈值（用以检测求解结果）
16.0         threshold

# 以下八行 L分解的方式
1            # of panel fact  使用几种分解方法
2            PFACTs (0=left, 1=Crout, 2=Right)  #使用的分解方法
1            # of recursive stopping criterium  使用几种停止递归的判断标准
4            NBMINs (>= 1)  #具体的标准数值（须不小于1）
1            # of panels in recursion  #递归中用几种分割法
2            NDIVs  #即每次递归分成几块
1            # of recursive panel fact.  用几种递归分解方法
1            RFACTs (0=left, 1=Crout, 2=Right) #选择的矩阵作消元

# 以下两行 L的广播方式
1            # of broadcast  #用几种向前看的步数
1            BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM)

# 以下两行 刚波通信深度
1            # of lookahead depth
1            DEPTHs (>=0)  #小规模集群取值1或2 大规模集群取值2到5

# 以下两行 U的广播算法
2            SWAP (0=bin-exch,1=long,2=mix)  #binary exchange  或 long 或 二者混合
64           swapping threshold  #采用混合的交换算法时使用的阈值

# 以下两行 L和U的数据存放格式（数据在内存的存放方式——行存放和列存放）
0            L1 in (0=transposed,1=no-transposed) form  #L1是否用转置形式
0            U  in (0=transposed,1=no-transposed) form  #U是否用转置形式表示

# 以下一行 平衡策略
1            Equilibration (0=no,1=yes)

# 以下一行 内存地址对齐
8            memory alignment in double (> 0)

##### This line (no. 32) is ignored (it serves as a separator). ######
0                               Number of additional problem sizes for PTRANS
1200 10000 30000                values of N
0                               number of additional blocking sizes for PTRANS
40 9 8 13 13 20 16 32 64        values of NB
```



## blas、lapack、atlas、openblas、mkl和cuBLAS

- BLAS的全称是Basic Linear Algebra Subprograms，基础线性代数子程序，由Netlib用fortran实现。它定义了一组应用程序接口（API）标准，是一系列初级操作的规范，如向量之间的乘法、矩阵之间的乘法等，是一组向量和矩阵运行的接口（API）规范。
- LAPACK （linear algebra package），是著名的线性代数库，也是Netlib用fortran语言编写的一组科学计算（矩阵运算）的接口规范，其底层是BLAS，在此基础上定义了很多矩阵和向量高级运算的函数，如矩阵分解、求逆和求奇异值等。该库的运行效率比BLAS库高。
- atlas和openblas等是BLAS的其他第三方实现，atlas和openblas均为开源社区项目，它们都实现了BLAS的全部功能，以及LAPACK的部分功能，并且他们都对计算过程进行了优化。

  - Atlas （Automatically Tuned Linear Algebra Software）能根据硬件，在运行时，自动调整运行参数。Openblas在编译时根据目标硬件进行优化，生成运行效率很高的程序或者库。

  - Openblas的优化是在编译时进行的，所以其运行效率一般比atlas要高，但这也决定了openblas对硬件依赖性高，更换硬件后可能需要重新编译。
- MKL由Intel推出，ACML由AMD推出，对intel/AMD的cpu架构进行了相关计算过程的优化，实现算法效率也很高。
- cuBLAS由NVIDIA推出，用以在NVIDIA GPU上做矩阵运算。