# frozen_string_literal: true

require "test_helper"
require "csv"
require "json"

class ExportsControllerTest < ActionDispatch::IntegrationTest
  def load_fixture(file_name)
    JSON.parse(File.read(Rails.root.join("test", "fixtures", "files", file_name)))
  end

  def test_return_csv_with_grouped_data
    payload = load_fixture("payload_teste_tecnico.json")

    post exports_url,
         params: payload.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :success
    assert_equal "text/csv; charset=utf-8", @response.content_type

    csv = CSV.parse(@response.body, headers: true)
    assert_equal 18, csv.size

    verify_csv_row_data(csv.first)
  end

  def test_return_csv_with_empty_payload
    post exports_url,
         params: [].to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :success
    assert_equal "text/csv; charset=utf-8", @response.content_type
    csv = CSV.parse(@response.body, headers: true)
    assert_equal 0, csv.size
  end

  def test_return_csv_with_no_liquidation_date
    payload = load_fixture("payload_teste_tecnico.json")

    post exports_url,
         params: payload.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :success
    assert_equal "text/csv; charset=utf-8", @response.content_type

    csv = CSV.parse(@response.body, headers: true)
    assert_equal 18, csv.size

    verify_liquidation_date(payload, csv)
  end

  private

  def verify_liquidation_date(payload, csv)
    payload.each do |transacao|
      next unless transacao["parcelas_detalhadas"].blank?

      data_compra = Date.parse(transacao["data_compra"])
      data_liquidacao = data_compra + 30.days
      verify_csv_for_liquidation_date(transacao, data_liquidacao, csv)
    end
  end

  def verify_csv_for_liquidation_date(transacao, data_liquidacao, csv)
    csv.each do |row|
      if row["cnpj_lojista"] == transacao["cnpj_lojista"] && row["valor_total"] == transacao["valor_total"].to_s
        assert_equal data_liquidacao.strftime("%Y-%m-%d"), row["data_liquidacao"]
      end
    end
  end

  def verify_csv_row_data(row)
    assert_equal "MASTER", row["bandeira"]
    assert_equal "98.765.432/0001-99",    row["cnpj_lojista"]
    assert_equal "2025-04-17",            row["data_liquidacao"]
    assert_equal "99.11", row["valor_total"]
    assert row["identificacao_unica"], row["identificacao_unica"]
  end
end
