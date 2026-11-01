<?php

namespace Database\Seeders;

use App\Models\Stock;
use Illuminate\Database\Seeder;

class StockSeeder extends Seeder
{
    public function run(): void
    {
        $rows = [
            'BBCA' => 'Bank Central Asia', 'BBRI' => 'Bank Rakyat Indonesia', 'BMRI' => 'Bank Mandiri',
            'BBNI' => 'Bank Negara Indonesia', 'TLKM' => 'Telkom Indonesia', 'ASII' => 'Astra International',
            'ANTM' => 'Aneka Tambang', 'GOTO' => 'GoTo Gojek Tokopedia', 'UNVR' => 'Unilever Indonesia',
            'ICBP' => 'Indofood CBP', 'ADRO' => 'Adaro Energy', 'BUKA' => 'Bukalapak',
            'INDF' => 'Indofood Sukses Makmur', 'KLBF' => 'Kalbe Farma', 'PGAS' => 'Perusahaan Gas Negara',
            'PTBA' => 'Bukit Asam', 'SMGR' => 'Semen Indonesia', 'MDKA' => 'Merdeka Copper Gold',
        ];
        foreach ($rows as $code => $name) {
            Stock::updateOrCreate(['code' => $code], ['name' => $name]);
        }
    }
}
