#!/usr/bin/env bash
set -euo pipefail

# 项目工作目录
WORK_DIR="/home/lurui/state"
# miniconda 安装路径
CONDA_INSTALL_PATH="/home/lurui/miniconda3/"
# miniconda 中的环境名
VENV_NAME="Vcell"

# 请将此路径更改为训练好的模型检查点（.ckpt）所在的目录
MODEL_DIR="/home/lurui/state/tx_train_experiment/cellline_10.13.1/checkpoints/final.ckpt"

# 输入数据配置文件
INPUT_ADATA="/path/to/your/infer_data.toml"

# 输出目录：用于存储预测结果的新目录
OUTPUT_DIR="./inference_output"

echo "切换到工作目录: ${WORK_DIR}"
cd "${WORK_DIR}" || {
    echo "错误：无法进入目录 ${WORK_DIR}"
    exit 1
}

echo "激活 miniconda 环境: ${VENV_NAME}"
if [ ! -d "${CONDA_INSTALL_PATH}" ]; then
    echo "错误：miniconda 安装路径 ${CONDA_INSTALL_PATH} 不存在！"
    echo "请修改脚本中的 CONDA_INSTALL_PATH 为您的实际路径"
    exit 1
fi
source "${CONDA_INSTALL_PATH}/etc/profile.d/conda.sh" || {
    echo "错误：无法加载 conda 初始化脚本，请检查 CONDA_INSTALL_PATH 是否正确"
    exit 1
}

echo "正在激活环境：${VENV_NAME}"
conda activate "${VENV_NAME}" || {
    echo -e "\n错误：激活环境失败！请检查环境名称或是否存在"
    exit 1
}
echo "当前激活的环境：$(conda info --envs | grep '*' | awk '{print $1}')（激活成功）"

echo "创建输出目录：$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "开始执行推理任务..."
state tx infer \
    --model_dir "$MODEL_DIR" \
    --pert_col "target_gene" \
    --cell_type_col "cell_type" \
    --toml_config_path "${INFER_CONFIG}" \
    --output "$OUTPUT_DIR"


if [ $? -eq 0 ]; then
    echo "=================================================="
    echo "推理任务完成！"
    echo "预测结果已保存到目录：${WORK_DIR}/${OUTPUT_DIR}"
    echo "=================================================="
else
    echo "错误：推理任务执行失败"
    exit 1
fi