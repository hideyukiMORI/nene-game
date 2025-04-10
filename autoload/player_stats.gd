extends Node

# 基本ステータス
@export var base_max_health: float = 100.0
@export var current_health: float = 100.0

# 一時的な増加（アイテム効果など）
var temporary_health_bonus: float = 0.0
# 永続的な増加（レベルアップなど）
var permanent_health_bonus: float = 0.0

signal health_changed(current: float, max: float)
signal health_depleted
signal max_health_changed(new_max: float)

# autoload/player_stats.gd
const SAVE_KEY_BASE_MAX_HEALTH = "base_max_health"
const SAVE_KEY_CURRENT_HEALTH = "current_health"
const SAVE_KEY_PERMANENT_BONUS = "permanent_health_bonus"

# 最大体力の計算（基本値 + 永続的ボーナス + 一時的ボーナス）
func get_max_health() -> float:
    return base_max_health + permanent_health_bonus + temporary_health_bonus

# 現在の体力を設定
func set_health(value: float) -> void:
    current_health = clamp(value, 0.0, get_max_health())
    health_changed.emit(current_health, get_max_health())
    if current_health <= 0:
        health_depleted.emit()

# 体力を回復
func heal(amount: float) -> void:
    set_health(current_health + amount)

# ダメージを受ける
func take_damage(amount: float) -> void:
    set_health(current_health - amount)

# 永続的な体力上限増加（レベルアップなど）
func add_permanent_health_bonus(amount: float) -> void:
    permanent_health_bonus += amount
    max_health_changed.emit(get_max_health())
    set_health(current_health)

# 一時的な体力上限増加（アイテム効果など）
func add_temporary_health_bonus(amount: float) -> void:
    temporary_health_bonus += amount
    max_health_changed.emit(get_max_health())
    set_health(current_health)

# 一時的な体力上限増加を解除
func remove_temporary_health_bonus(amount: float) -> void:
    temporary_health_bonus = max(0.0, temporary_health_bonus - amount)
    max_health_changed.emit(get_max_health())
    set_health(current_health)

# 現在の体力を取得
func get_health() -> float:
    return current_health

# 体力の割合を取得（0.0 ～ 1.0）
func get_health_ratio() -> float:
    return current_health / get_max_health()

func save_stats() -> void:
    var _save_data = {
        SAVE_KEY_BASE_MAX_HEALTH: base_max_health,
        SAVE_KEY_CURRENT_HEALTH: current_health,
        SAVE_KEY_PERMANENT_BONUS: permanent_health_bonus
    }
    # TODO: セーブデータの保存処理

func load_stats() -> void:
    # TODO: セーブデータの読み込み処理
    pass
