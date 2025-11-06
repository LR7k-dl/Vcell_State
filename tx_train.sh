#!/usr/bin/env bash
set -euo pipefail

# 定义关键路径和环境名
WORK_DIR="/home/lurui/state"
CONDA_INSTALL_PATH="/home/lurui/miniconda3/"
VENV_NAME="Vcell"  # miniconda 中的环境名

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
echo "当前激活的环境：$(conda itx_train_perturbationnfo --envs | grep '*' | awk '{print $1}')（激活成功）"

# 执行训练命令（已移除无效参数）
echo "开始执行训练任务..."
export CUDA_VISIBLE_DEVICES=1
python -m state tx train \
    data.kwargs.toml_config_path="/home/lurui/state/tx_train_cellline.toml" \
    data.kwargs.num_workers=8 \
    +data.kwargs.persistent_workers=false \
    data.kwargs.pin_memory=false \
    data.kwargs.batch_col="batch_var" \
    data.kwargs.pert_col="target_gene" \
    data.kwargs.cell_type_key="cell_type" \
    data.kwargs.control_pert="non-targeting" \
    data.kwargs.perturbation_features_file="ESM2_pert_features.pt" \
    training.max_steps=500 \
    training.val_freq=10 \
    training.ckpt_every_n_steps=20000 \
    model.kwargs.batch_encoder=false \
    model=state \
    model.kwargs.loss=energy \
    wandb.tags=first_run \
    output_dir="tx_train_experiment" \
    name="cellline_11.3.1" \
    +callbacks.early_stopping.enable=true \
    +training.monitor="val_pr_auc" \
    +training.early_stopping_mode="max" \
    +training.early_stopping_patience=15
#  /home/lurui/state/ST-Tahoe/final.ckpt
#  model.checkpoint="/home/lurui/state/ST-Tahoe/final.ckpt" \
#  training.val_freq=10 \

#  损失函数有3个可选：mse、energy（给的config基本上都是energy）、se（也就是论文中的combinedloss，但是注意要设置参数）

#  基因扰动预测任务注重排名前后和错误率，PR-AUC（精确率-召回率曲线下面积）专注于正样本。
#  它只有在模型能够以高精确率（预测的显著基因是真的）和高召回率（真的显著基因被找出来）的情况下才会提高
#  因此选择 val_pr_auc 作为监控指标，并设置为最大化

#  顺便完成预测任务
python -m state tx predict --output_dir /home/lurui/state/tx_train_experiment/cellline_11.3.1 --checkpoint /home/lurui/state/tx_train_experiment/cellline_11.3.1/checkpoints/final.ckpt

# 检查训练是否成功
if [ $? -eq 0 ]; then
    echo "训练任务完成，输出目录：${WORK_DIR}/tx_train_experiment"
else
    echo "错误：训练任务执行失败"
    exit 1
fi