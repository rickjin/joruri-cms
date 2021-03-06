# encoding: utf-8
class Sys::Setting < Sys::Model::Base::Setting
  validates :name, presence: true

  set_config :change_user_name,
             name: "ログインユーザーによるユーザー情報の変更",
             options: [%w(許可 allowed), ['拒否（標準）', 'denied']],
             default: :denied

  set_config :change_user_password,
             name: "ログインユーザーによるパスワードの変更",
             options: [%w(許可 allowed), ['拒否（標準）', 'denied']],
             default: :denied
end
