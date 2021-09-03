//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./Agreement.sol";

contract Listing{

    struct Category{
        string ipfs_hash;
        uint256 parent_id;
        bool is_parent;
    }

    mapping(uint256 => Category) public categories;
    mapping(uint256 => uint256[]) public sub_category_index;
    mapping (uint256=> mapping(address => uint256[])) public list;
    uint256[] public parent_category_index;
    uint256 public cat_id;

    function addNewGig(address factory, uint256 id, uint256 category_id) public{
        AgreementToken agreement = AgreementToken(factory);

        agreement.transferFrom(msg.sender, address(this), id);

        list[category_id][factory].push(id);
    }


    function transferGig(address factory, uint256 id, address new_destination) public{
        AgreementToken agreement = AgreementToken(factory);
        require(agreement.ownerOf(id) == msg.sender);

        agreement.transfer(new_destination, id);
    }


    function createCategory(string memory ipfs_hash, bool is_parent, uint256 parent_id) public{

        if(!is_parent) require(categories[parent_id].is_parent == true);

        cat_id++;

        categories[cat_id] = Category(ipfs_hash, parent_id, is_parent);
        
        if(is_parent){
            parent_category_index.push(cat_id);
        }else{
            sub_category_index[parent_id].push(cat_id);
        }
    }


    function deleteCategory(uint256 id, uint256 index) public{
        Category memory selected_category = categories[id];

        if(selected_category.is_parent){
            require(parent_category_index[index] == id, "Wrong index");

            parent_category_index[index] = parent_category_index[parent_category_index.length - 1];
            delete parent_category_index[parent_category_index.length - 1];
            parent_category_index.pop();
        }else{
            uint256 parent_id = selected_category.parent_id;

            require(sub_category_index[parent_id][index] == id, "Wrong index");

            sub_category_index[parent_id][index] = sub_category_index[parent_id][sub_category_index[parent_id].length - 1];
            delete sub_category_index[parent_id][sub_category_index[parent_id].length - 1];
            sub_category_index[parent_id].pop();
        }

        delete categories[id];
    }

    function getParentCategories() public view returns(Category[] memory){

        Category[] memory tmp_category = new Category[](parent_category_index.length);

        for(uint i=0 ; i < parent_category_index.length; i++){

            tmp_category[i] = categories[parent_category_index[i]];
        }
        
        return tmp_category;
    }

    function getSubCategories(uint256 parent_id) public view returns(Category[] memory){

        Category[] memory tmp_category  = new Category[](sub_category_index[parent_id].length);

        for(uint i=0 ; i < sub_category_index[parent_id].length; i++){

            tmp_category[i] = categories[sub_category_index[parent_id][i]];
        }
        
        return tmp_category;
    }
    
    function totalCategories() public view returns(uint256){
        return parent_category_index.length;
    }
    
    function totalSubCategories(uint256 parent_id) public view returns(uint256){
        return sub_category_index[parent_id].length;
    }
    
}