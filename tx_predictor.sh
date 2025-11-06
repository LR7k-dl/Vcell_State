#!/usr/bin/env bash
set -euo pipefail

# 定义关键路径和环境名
WORK_DIR="/home/lurui/state"
CONDA_INSTALL_PATH="/home/lurui/miniconda3/"
VENV_NAME="Vcell"

# 切换到工作目录
echo "切换到工作目录: ${WORK_DIR}"
cd "${WORK_DIR}" || {
    echo "错误：无法进入目录 ${WORK_DIR}"
    exit 1
}

# 激活 miniconda 环境
echo "激活 miniconda 环境: ${VENV_NAME}"
if [ ! -d "${CONDA_INSTALL_PATH}" ]; then
    echo "错误：miniconda 安装路径 ${CONDA_INSTALL_PATH} 不存在！"
    echo "请修改脚本中的 CONDA_INSTALL_PATH 为你的实际路径"
    exit 1
fi
source "${CONDA_INSTALL_PATH}/etc/profile.d/conda.sh" || {
    echo "错误：无法加载 conda 初始化脚本，请检查 CONDA_INSTALL_PATH 是否正确"
    exit 1
}

# 激活 Vcell 环境
echo "正在激活环境：${VENV_NAME}"
conda activate "${VENV_NAME}" || {
    echo -e "错误：激活环境失败！请检查以下两点："
    echo "环境名是否正确（当前设置为 ${VENV_NAME}）"
    echo "执行 'conda env list' 查看系统中是否存在该环境"
    exit 1
}
echo "当前激活的环境：$(conda info --envs | grep '*' | awk '{print $1}')（激活成功）"

# 执行预测命令
echo "开始执行预测任务..."
python -m state tx predict --output_dir /home/lurui/state/tx_train_experiment/perturbation_10.31.2 --checkpoint /home/lurui/state/tx_train_experiment/perturbation_10.31.2/checkpoints/final.ckpt

# 检查预测是否成功
if [ $? -eq 0 ]; then
    echo "任务完成，输出目录：${WORK_DIR}/tx_train_experiment"
else
    echo "错误：训练任务执行失败"
    exit 1
fi
