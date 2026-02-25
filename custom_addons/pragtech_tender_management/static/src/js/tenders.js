/** @odoo-module **/
import { whenReady } from "@odoo/owl";

whenReady(() => {
    const $ = window.$;
    if (!$ || !document.querySelector('.material_input_amount')) {
        return;
    }

    $('.material_input_amount').css('display','none');
    $('.labour_input_amount').css('display','none');
    $('.overhead_input_amount').css('display','none');
    $('.total_input_amount').css('display','none');

    function recalcTotal() {
        var mat_all = $('.material_amount');
        var lab_all = $('.labour_amount');
        var overhead_all = $('.overhead_amount');
        var all_tot = 0.00;

        for (var i = 0; i < mat_all.length; i++) {
            all_tot += Number(mat_all[i].innerText);
        }
        for (var i = 0; i < lab_all.length; i++) {
            all_tot += Number(lab_all[i].innerText);
        }
        for (var i = 0; i < overhead_all.length; i++) {
            all_tot += Number(overhead_all[i].innerText);
        }

        $('#total_amount').html(all_tot);
        $('#total_amount_duplicate').val(all_tot);
    }

    $('input[class=material_your_price]').change(function(event) {
        if (event && event.currentTarget && event.currentTarget.attributes && event.currentTarget.attributes.my_id) {
            var id = event.currentTarget.attributes.my_id.value;
            var qty = '#material_quantity-' + id + ' span';
            var price = 'input[name=material_your_price-' + id + ']';
            var material_amount_duplicate = 'material_amount_duplicate-' + id;

            var a = $(qty).text();
            var b = $(price)[0].value;

            var aValue = parseFloat(a.replace(/[^0-9.-]+/g, ""));
            var bValue = parseFloat(b.replace(/[^0-9.-]+/g, ""));

            var material_amount = aValue * bValue;

            $('#material_amount-' + id + ' span').text(material_amount);
            $('[name="' + material_amount_duplicate + '"]').val(material_amount);

            recalcTotal();
        }
    });

    $('input[class=labour_your_price]').change(function(event) {
        if (event && event.currentTarget && event.currentTarget.attributes && event.currentTarget.attributes.my_id) {
            var id = event.currentTarget.attributes.my_id.value;
            var qty2 = '#labour_quantity-' + id + ' span';
            var price2 = 'input[name=labour_your_price-' + id + ']';
            var labour_amount_duplicate = 'labour_amount_duplicate-' + id;

            var a2 = $(qty2).text();
            var b2 = $(price2)[0].value;

            var aValue2 = parseFloat(a2.replace(/[^0-9.-]+/g, ""));
            var bValue2 = parseFloat(b2.replace(/[^0-9.-]+/g, ""));

            var labour_amount = aValue2 * bValue2;

            $('#labour_amount-' + id + ' span').text(labour_amount);
            $('[name="' + labour_amount_duplicate + '"]').val(labour_amount);

            recalcTotal();
        }
    });

    $('input[class=overhead_your_price]').change(function(event) {
        if (event && event.currentTarget && event.currentTarget.attributes && event.currentTarget.attributes.my_id) {
            var id = event.currentTarget.attributes.my_id.value;
            var qty3 = '#overhead_quantity-' + id + ' span';
            var price3 = 'input[name=overhead_your_price-' + id + ']';
            var overhead_amount_duplicate = 'overhead_amount_duplicate-' + id;

            var a3 = $(qty3).text();
            var b3 = $(price3)[0].value;

            var aValue3 = parseFloat(a3.replace(/[^0-9.-]+/g, ""));
            var bValue3 = parseFloat(b3.replace(/[^0-9.-]+/g, ""));

            var overhead_amount = aValue3 * bValue3;

            $('#overhead_amount-' + id + ' span').text(overhead_amount);
            $('[name="' + overhead_amount_duplicate + '"]').val(overhead_amount);

            recalcTotal();
        }
    });
});
