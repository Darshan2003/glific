defmodule GlificWeb.Schema.UserTypes do
  @moduledoc """
  GraphQL Representation of Glific's User DataType
  """
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Glific.Repo
  alias GlificWeb.Resolvers
  alias GlificWeb.Schema.Middleware.Authorize

  object :user_result do
    field :user, :user
    field :errors, list_of(:input_error)
  end

  object :user do
    field :id, :id
    field :name, :string
    field :phone, :string
    field :roles, list_of(:role_label)

    field :inserted_at, :datetime
    field :updated_at, :datetime

    field :is_restricted, :boolean do
      resolve(fn user, _, %{context: %{current_user: current_user}} ->
        if Enum.member?(current_user.roles, :staff),
          do: {:ok, nil},
          else: {:ok, user.is_restricted}
      end)
    end

    field :contact, :contact do
      resolve(dataloader(Repo))
    end

    field :language, :language do
      resolve(dataloader(Repo))
    end

    field :groups, list_of(:group) do
      resolve(dataloader(Repo))
    end

    field :access_roles, list_of(:access_role) do
      resolve(dataloader(Repo))
    end

    field :organization, :organization do
      resolve(dataloader(Repo))
    end
  end

  object :role do
    field :id, :id
    field :label, :string
  end

  @desc "Filtering options for users"
  input_object :user_filter do
    @desc "Match the name"
    field :name, :string

    @desc "Match the phone"
    field :phone, :string
  end

  input_object :current_user_input do
    field :name, :string
    field :password, :string
    field :otp, :string
    field :language_id, :id
  end

  input_object :user_input do
    field :name, :string
    field :roles, list_of(:role_label)
    field :group_ids, list_of(:id)
    field :is_restricted, :boolean
    field :language_id, :id
    field :add_role_ids, list_of(:id)
    field :delete_role_ids, list_of(:id)
  end

  object :user_queries do
    @desc "get the details of one user"
    field :user, :user_result do
      arg(:id, non_null(:id))
      middleware(Authorize, :staff)
      resolve(&Resolvers.Users.user/3)
    end

    @desc "Get a list of all users filtered by various criteria"
    field :users, list_of(:user) do
      arg(:filter, :user_filter)
      arg(:opts, :opts)
      middleware(Authorize, :staff)
      resolve(&Resolvers.Users.users/3)
    end

    @desc "Get a count of all users filtered by various criteria"
    field :count_users, :integer do
      arg(:filter, :user_filter)
      middleware(Authorize, :staff)
      resolve(&Resolvers.Users.count_users/3)
    end

    @desc "Get the details of current user"
    field :current_user, :user_result do
      middleware(Authorize, :staff)
      resolve(&Resolvers.Users.current_user/3)
    end
  end

  object :user_mutations do
    field :update_current_user, :user_result do
      arg(:input, non_null(:current_user_input))
      middleware(Authorize, :staff)
      resolve(&Resolvers.Users.update_current_user/3)
    end

    field :delete_user, :user_result do
      arg(:id, non_null(:id))
      middleware(Authorize, :manager)
      resolve(&Resolvers.Users.delete_user/3)
    end

    field :update_user, :user_result do
      arg(:id, non_null(:id))
      arg(:input, non_null(:user_input))
      middleware(Authorize, :manager)
      resolve(&Resolvers.Users.update_user/3)
    end
  end
end
