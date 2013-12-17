
%= hidden_field 'delete_contributor';

% my @cons = $object->get_publication(autocreate => 1)->contributors;
<table class='table table-condensed table-bordered'>
    <tr>
        <th>Person</th><th>Organization</th><th>Role</th>
    </tr>
% for my $con (@cons) {
<tr>
<td class='row'>
    <td><%= $con->person %></td>
    <td><%= $con->organization %></td>
    <td><%= $con->role %></td>
</tr>

<td><%= tag 'button' => class => 'btn btn-danger squeezevert' => onClick => qq[{this.form.elements["delete_contributor"].value = '].$keyword->identifier.qq['; this.form.submit(); }] => begin %>delete<%= end %></td>
</tr>
% }
</table>

